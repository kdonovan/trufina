require 'net/http'
require 'net/https'
require 'ostruct'

require 'nokogiri'

class Trufina
  class TrufinaException < StandardError; end
  class ConfigFileNotFoundError < TrufinaException; end
  class TemplateFileNotFoundError < TrufinaException; end
  class MissingToken < TrufinaException; end
  class NetworkError < TrufinaException; end
  class RequestFailure < TrufinaException; end
  
  # Helper method for reading in config data
  def self.recursively_symbolize_keys!(hash)
    hash.symbolize_keys!
    hash.values.select{|v| v.is_a? Hash}.each{|h| recursively_symbolize_keys!(h)}
  end
  
  # Setting class-wide configuration info from yaml file
  begin
    @@config_path = File.join(RAILS_ROOT, 'config', 'trufina.yml')
    @@config = YAML.load(ERB.new(File.read(@@config_path)).result)
    recursively_symbolize_keys!(@@config)
    cattr_reader :config
  rescue
    raise ConfigFileNotFoundError.new("No config at #{@@config_path}")
  end
  
  # Setting instance-specific runtime mode (production / staging)
  attr_reader :mode  
  %w(staging production).each do |mode|
    define_method "#{mode}!" do
      @mode = mode
    end
    define_method "#{mode}?" do
      @mode == mode
    end
  end
  
  def initialize
    staging! # TODO - default to production once done testing
  end
  
  # FOR TESTING -- read in xml fixture files
  def self.read(xml_file)
    response_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'test', 'fixtures', 'responses'))
    File.read( File.join(response_dir, "#{xml_file}.xml") )
  end
    
  # Creates and sends a login request for the specified PRT
  # a = Trufina.new.login_request(Time.now)
  def login_request(prt)
    xml = render(:login_request, LoginRequest.new(prt))
    send(xml)
  end

  # Given a PRT, send the login request an return the redirect URL
  #
  # Sends login request to get a PLID from Trufina, then uses that to build
  # a redirect URL specific to this user.
  # 
  # Once user completes filling out their information and makes it available
  # to us, Trufina will ping us with an access_notification to let us know
  # it's there and we should ask for it.
  def redirect_url(prt, opts = {})
    plid = login_request(prt).plid
    redirect_url_from_plid( plid, opts )
  end

  # This should be exposed to the internet to receive Trufina's postback after
  # a user follows the redirect_url and completes a profile
  # 
  # Receives the access notification, and automatically sends a request for
  # the actual information.
  def handle_access_notification(raw_xml)
    ready_to_access = Trufina::XML.new(raw_xml)
    # return {:tnid => ready_to_access.tnid, :prt => ready_to_access.prt}
    # Could return info, but might as well continue on to the info_request
    info_request( ready_to_access.tnid )
  end

  # Given a TNID, send info request
  def info_request(tnid)
    xml = render(:info_request, InfoRequest.new(tnid))
    data = send(xml)
    {:pur => data.pur, :prt => data.prt, :data => data.returned_info}
  end



  protected

  def domain
    staging? ? 'staging.trufina.com' : 'www.trufina.com'
  end
  
  def endpoint
    '/WebServices/API/'
  end


  # Send the specified XML to Trufina's servers
  def send(xml)
    # Connection Info
    api = Net::HTTP.new( domain, 443 )
    api.use_ssl = true
    api.verify_mode = OpenSSL::SSL::VERIFY_NONE # Prevent annoying warnings
    
    # Request info
    method_call = Net::HTTP::Post.new( endpoint, {'Content-Type' => 'text/xml'} )
    method_call.body = xml
    if staging? # TODO: unclear if prod site requires another set of credentials
      method_call.basic_auth(config[:staging_access][:username], config[:staging_access][:password])
    end
    
    # OK, execute the actual call
    response = api.request(method_call)
    raise NetworkError.new(response.msg) unless response.is_a?(Net::HTTPSuccess)
    debugger
    puts response.body
    return Trufina::XML.new(response.body)
  end
  
  # Given a PLID (from a login_request), return a url to send the user to
  def redirect_url_from_plid(plid, opts = {})
    path = (staging? && opts[:demo]) ? "/DemoPartnerLogin/DemoLogin/#{plid}" : "/PartnerLogin/Login/#{plid}"
    "http://#{domain}#{path}"
  end
  
  # Renders the appropriate template for the specified method call
  def render(template_name, template_binding_object)
    template_file = File.join(File.dirname(__FILE__), '..', 'templates', "#{template_name}.erb")
    raise TemplateFileNotFoundError unless File.exists?(template_file)

    template = ERB.new(File.read(template_file))
    template.result(template_binding_object.get_binding)
  end
end

# prt = Time.now # later on use user ID
# api = Trufina.new
# 
# plid = api.login_request( prt )
# api.redirect_url(plid)


# Can access api.login_request directly, but easiest just to do:
# Trufina.new.redirect_url 'some_id', :demo => true