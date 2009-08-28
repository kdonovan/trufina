require 'net/http'
require 'net/https'
require 'ostruct'

require 'nokogiri'

class Trufina
  class TrufinaException < StandardError; end
  class ConfigFileNotFoundError < TrufinaException; end
  class TemplateFileNotFoundError < TrufinaException; end
  class MissingPartnerReferenceToken < TrufinaException; end
  class NetworkError < TrufinaException; end
  class RequestFailure < TrufinaException; end

  # Base class for template binding objects.  Each remote call has a local template, and
  # template rendering grabs the binding from a TemplateBinding object to lookup variables.
  class TemplateBinding
    def initialize *args
      @config = Trufina.config
    end

    def get_binding
      binding
    end
  end

  # TemplateBinding object for login requests
  class LoginRequest < TemplateBinding
    def initialize(prt)
      super
      raise MissingPartnerReferenceToken if prt.blank?
      @prt = prt
    end
  end
  
  # Helper method for reading in config data
  def self.recursively_symbolize_keys!(hash)
    hash.symbolize_keys!
    hash.values.select{|v| v.is_a? Hash}.each{|h| recursively_symbolize_keys!(h)}
  end
  
  
    
  class XML
    def self.namespace
      "http://www.trufina.com/truapi/1/0"
    end
        
    attr_accessor :xml
    
    def initialize(str)
      @xml = Nokogiri::XML(str).root
      
      # Check for errors
      if @xml.name == 'TrufinaRequestFailure'
        error = @xml.xpath('//xmlns:Error').first
        raise RequestFailure.new("#{error.attributes['kind']}: #{error.text}")
      end
      
      @xml
    end
    
    
    AUTH_ITEMS = %w(PRT PLID TNID PUR)
    AUTH_ITEMS.each do |token|
      define_method token.downcase do
        node = @xml.xpath("//trufina:#{token}", 'trufina' => Trufina::XML.namespace).first
        node ? node.text : nil
      end
    end

  end
  
  
  
  # Setting class-wide configuration info from yaml file
  begin
    @@config_path = File.join(RAILS_ROOT, 'config', 'trufina.yml')
    @@config = YAML.load(ERB.new(File.read(@@config_path)).result)
    recursively_symbolize_keys!(@@config)
    cattr_reader :config
  rescue
    raise ConfigFileNotFoundError
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
  
  def domain
    staging? ? 'staging.trufina.com' : 'www.trufina.com'
  end
  
  def endpoint
    '/WebServices/API/'
  end
  
    
  # Creates and sends a login request for the specified PRT
  # a = Trufina.new.login_request(Time.now)
  def login_request(prt)
    xml = render(:login_request, LoginRequest.new(prt))
    send(xml).plid
  end

  # Given a PRT, send the login request an return the redirect URL
  def redirect_url(prt, opts = {})
    plid = login_request(prt)
    redirect_url_from_plid( plid, opts )
  end

  protected

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