require 'net/http'
require 'ostruct'

class Trufina
  class TrufinaException < StandardError; end
  class ConfigFileNotFoundError < TrufinaException; end
  class TemplateFileNotFoundError < TrufinaException; end
  class MissingPartnerReferenceToken < TrufinaException; end
  
  # Setting class-wide configuration info from yaml file
  begin
    @@config_path = File.join(RAILS_ROOT, 'config', 'trufina.yml')
    @@config = YAML.load(ERB.new(File.read(@@config_path)).result).symbolize_keys
    cattr_reader :config
  rescue
    raise ConfigFileNotFoundError
  end
  
  # Setting instance-specific runtime mode (production / staging)
  @mode = :production
  attr_reader :mode
  %w(staging production).each do |mode|
    define_method "#{mode}!" do
      @mode = mode
    end
    define_method "#{mode}?" do
      @mode == mode
    end
  end
  
  def domain
    testing? ? 'https://staging.trufina.com' : 'https://www.trufina.com/'
  end
  
  def endpoint
    '/WebServices/API/'
  end
  
  def redirect_url(plid, demo = false)
    path = (testing? && demo) ? "/DemoPartnerLogin/Login/#{plid}" : "/PartnerLogin/Login/#{plid}"
    "#{domain}#{path}"
  end

  def login_request(prt)
    request = LoginObject.new(prt)
    render(:login_request, request.get_binding)
  end

  class RequestBinding
    def initialize *args
      @config = Trufina.config
    end

    def get_binding
      binding
    end
  end
  
  class LoginObject < RequestBinding
    def initialize(prt)
      super
      raise MissingPartnerReferenceToken if prt.blank?
      @prt = prt
    end
  end


  def send(path, xml)
    api = Net::HTTP.new( Trufina.domain )
    # api.use_ssl = true
    response, data = api.post(path, xml, {'Content-Type' => 'text/xml'})
  end
  
  
  def render(template_name, template_binding)
    template_file = File.join(File.dirname(__FILE__), '..', 'templates', "#{template_name}.erb")
    raise TemplateFileNotFoundError unless File.exists?(template_file)

    template = ERB.new(File.read(template_file))
    template.run(template_binding)
  end
  
end
