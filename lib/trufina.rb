require 'net/http'
require 'net/https'
require 'ostruct'
require 'open-uri'

require 'nokogiri'

class Trufina

  class << self
    
    # Creates and sends a login request for the specified PRT
    # 
    #   Trufina.login_request(Time.now)
    #   Trufina.login_request(Time.now, [:phone], {:name => {:first => 'Foo', :surname => 'Bar'}})
    def login_request(prt, requested_data = [], seed_data = nil)
      requested_data ||= {:name => [:first, :surname]}
      seed_data ||= []
      xml = LoginRequest.new(:prt => prt, :data => requested_data, :seed => seed_data).render
      sendToTrufina(xml)
    end

    # Given a PRT, send the login request an return the redirect URL
    #
    # Sends login request to get a PLID from Trufina, then uses that to build
    # a redirect URL specific to this user.
    # 
    # Once user completes filling out their information and makes it available
    # to us, Trufina will ping us with an access_notification to let us know
    # it's there and we should ask for it.
    #
    # Options:
    #   * demo  -- Boolean value. If true, and Trufina.staging? is true, returns demo URL
    #   * requested -- Hash of requested info to be returned once the user is done with Trufina
    #   * seed  -- Hash of seed data used to prefill the user's forms at Trufina's website
    def redirect_url(prt, opts = {})
      plid = login_request(prt, opts.delete(:requested), opts.delete(:seed)).plid
      redirect_url_from_plid( plid, opts.delete(:demo) )
    end

    # This should be exposed to the internet to receive Trufina's postback after
    # a user follows the redirect_url and completes a profile
    # 
    # Receives the access notification, and automatically sends a request for
    # the actual information.
    def handle_access_notification(raw_xml)
      info_request( parseFromTrufina(raw_xml).tnid )
    end

    # Given a TNID, send info_request
    def info_request(tnid)
      xml = InfoRequest.new(:tnid => tnid).render
      sendToTrufina(xml)
    end

    # Given a TLID, send login_info_request
    def login_info_request(tlid)
      xml = LoginInfoRequest.new(:tlid => tlid).render
      sendToTrufina(xml)
    end

    # Given an auth hash containing PID, PAK, PUR, and PRT, as well as
    # a data hash containing any data fields we wish to request about the
    # specified user, sends a request for data off to Trufina.  Trufina will
    # respond immediately with a status of "pending" for the newly requested 
    # information, will notify the user via email that we're requesting new
    # info, and finally will notify us via an AccessNotification if/when the 
    # user grants us access to the additional data.
    def access_request(auth = {}, data = {})
      xml = AccessRequest.new( auth.merge(:data => data) ).render
      sendToTrufina(xml)
    end


    protected

    def domain
      staging? ? 'staging.trufina.com' : 'www.trufina.com'
    end
  
    def endpoint
      '/WebServices/API/'
    end

    def schema
      @@schema ||= XML::Schema.from_string(open("http://www.trufina.com/api/truapi.xsd").read)
    end

    # Send the specified XML to Trufina's servers
    def sendToTrufina(xml)
      # Connection Info
      api = Net::HTTP.new( domain, 443 )
      api.use_ssl = true
      api.verify_mode = OpenSSL::SSL::VERIFY_NONE # Prevent annoying warnings
    
      # Request info
      method_call = Net::HTTP::Post.new( endpoint, {'Content-Type' => 'text/xml'} )
      method_call.body = xml

      if Trufina::Config.staging? # TODO: unclear if production site requires another set of credentials
        method_call.basic_auth(Config.staging_access[:username], Config.staging_access[:password])
      end
    
      # OK, execute the actual call
      response = api.request(method_call)
      raise NetworkError.new(response.msg) unless response.is_a?(Net::HTTPSuccess)
      parseFromTrufina(response.body)
    end
  
    # Try to make something useful from Trufina's XML responses
    def parseFromTrufina(raw_xml)
      response = Trufina::Response.parse(raw_xml)
      
      # Raise exception if we've received an error
      if response.is_a?(Trufina::RequestFailure) # Big error -- the entire returned XML is to tell us
        raise TrufinaResponseException.new("#{response.error.kind}: #{response.error}")
      elsif response.respond_to?(:error) && response.error # Smaller error, noted inline
        raise TrufinaResponseException.new("Error in #{response.class.name}: #{response.error}")
      end
      
      return response
    end
     
    # Given a PLID (from a login_request), return a url to send the user to
    def redirect_url_from_plid(plid, is_demo = nil)
      path = (staging? && is_demo) ? "/DemoPartnerLogin/DemoLogin/#{plid}" : "/PartnerLogin/Login/#{plid}"
      "http://#{domain}#{path}"
    end
    
  end
end
