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
      raise MissingToken.new("No PRT provided") if prt.blank?
      @prt = prt
    end
  end

  # TemplateBinding object for info requests
  class InfoRequest < TemplateBinding
    def initialize(tnid)
      super
      raise MissingToken.new("No TNID provided") if tnid.blank?
      @tnid = tnid
    end
  end

  
  # Helper method for reading in config data
  def self.recursively_symbolize_keys!(hash)
    hash.symbolize_keys!
    hash.values.select{|v| v.is_a? Hash}.each{|h| recursively_symbolize_keys!(h)}
  end
  
  
    
  class XML
    # TODO - some trufina responses HAVE no namespace? wtf? fix this to detect that dynamically
    def namespace
      # "http://www.trufina.com/truapi/1/0"
      @xml.attributes['xmlns']
    end
        
    attr_accessor :xml
    
    def initialize(str)
      @xml = Nokogiri::XML(str).root
      check_for_errors
      return @xml
    end
    
    def name
      @xml.name
    end
    
    # Check for errors. TrufinaRequestFailure is clear, and has errors in the Trufina namespace
    # Unknown TNID error from info_request, on the other hand, has no special root name but has Error 
    # node with no namespace
    def check_for_errors
      if name == 'TrufinaRequestFailure' || @xml.xpath('//Error').first
        error = @xml.xpath('//Error').first
        error ||= @xml.xpath('//xmlns:Error').first # This must be second, because raises exception if no namespace defined
        raise RequestFailure.new("#{error.attributes['kind']}: #{error.text}")
      end
    end
    
    AUTH_ITEMS = %w(PRT PLID TNID PUR)
    AUTH_ITEMS.each do |token|
      define_method token.downcase do
        node = xpath_with_ns("//#{token}").first
        node ? node.text : nil
      end
    end

    # Detect if using a namespace, and use it if appropriate
    def xpath_with_ns(xpath)
      results = if namespace
        # Split '//node' or '/node' into '//' or '/' and 'node', insert the namespace, and recombine
        prefix = xpath[/\A\W+/]
        node_string = xpath[prefix.length, xpath.length]
        xpath = "#{prefix}trufina:#{node_string}"
        @xml.search( xpath, 'trufina' => namespace )
      else
        @xml.search( xpath )
      end
    end

    # Trufina::XML.create_accessors 'ATop' => ['a', 'b', {'c' => ['c1','c2','c3']}]
    # x = Trufina::XML.new("<ATop><a>aaa</a><b>bbb</b><c><c1>ccc111</c1><c2>ccc222</c2><c3>ccc333</c3></c></ATop>")
    @@created_accessors = []
    cattr_reader :created_accessors
    def self.create_accessors(node, xpath_prefix = '/', name_prefix = nil)
      case node
      when Array  # Simple -- just recurse to all array members
        node.each {|n| create_accessors(n, xpath_prefix, name_prefix) }

      when Hash   # Here we add nesting -- push each key on the prefix stack, then recurse for all values
        node.keys.each do |key|
          create_accessors(key, xpath_prefix, name_prefix)
          create_accessors(node[key], "#{xpath_prefix}/#{key}", build_name(key, name_prefix))
        end

      when String, Symbol   # Finally we actually do something -- build the actual method
        short_name =build_name(node)
        long_name = build_name(node, name_prefix)
        puts " #{long_name} (#{node.to_s.underscore}) - #{xpath_prefix}/#{node}"
        puts "     (name_prefix: #{name_prefix})"
        
        # Create a method whose name reflects the full node traversal to this point:
        # e.g. access_response_residence_address_postal_code for access_response > 
        # residence_address > postal_code
        define_method long_name do
          xpath_with_ns("#{xpath_prefix}/#{node}")
        end
        @@created_accessors << long_name
        
        # Alias e.g. access_response_residence_address_postal_code to postal_code, 
        # unless postal_code has already been defined as something else
        unless @@created_accessors.include?(short_name)
          define_method short_name do
            long_name
          end
        end
      end
    end
    
    def self.build_name(current, prefix = nil)
      [prefix, current].map{|n| n.to_s.underscore}.select{|n| !n.blank?}.join('_')
    end
    
  end
  
  class XML::InfoResponse < XML
    INFO_ITEMS = [
      'AccessResponse' => [
        {'Name' => %w(Prefix First Middle MiddleInitial Surname Suffix)},
        'Age',
        'DateOfBirth',
        'CountryOfBirth',
        'Phone',
        {'ResidenceAddress' => %w(StreetAddress StreetAddress City State PostalCode)},
        'Last4SSN'
      ]
    ]
    
    # Allows access like:
    # 
    # resp = Trufina::XML::InfoResponse.new(xml)
    # resp.name
    # 
    # 
    create_accessors INFO_ITEMS
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
  
  
    
  # Creates and sends a login request for the specified PRT
  # a = Trufina.new.login_request(Time.now)
  def login_request(prt)
    xml = render(:login_request, LoginRequest.new(prt))
    send(xml).plid
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
    plid = login_request(prt)
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
    send(xml)
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