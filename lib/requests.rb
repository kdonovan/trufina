# Contains all Trufina::Requests::* classes.

class Trufina
  
  # These classes are used to generate requests to the Trufina API.
  # There's a class in this module for each possible Trufina API call.
  module Requests

    API_NAMESPACE_URL = "http://www.trufina.com/truapi/1/0"
    class BaseRequest
      include AllowCreationFromHash

      def initialize(hash = {})
        super # init method in AllowCreationFromHash
        autofill_from_config
      end

      def render
        validate_contents
        # validate_against_schema # -- Functioning code doesn't validate, waiting for feedback from Trufina before implementing
        to_xml
      end
    
      protected
    
      # Automatically assign any required auth or URL information from the global config
      def autofill_from_config
        self.pid ||= Config.credentials[:PID] if self.respond_to?(:pid=)
        self.pak ||= Config.credentials[:PAK] if self.respond_to?(:pak=)
      
        # Note: URLs are optional fields, but prefilling from config anyway
        self.cancel_url  ||= Config.endpoints[:cancel]  if self.respond_to?(:cancel_url=)
        self.success_url ||= Config.endpoints[:success] if self.respond_to?(:success_url=)
        self.failure_url ||= Config.endpoints[:failure] if self.respond_to?(:failure_url=)
      end
    
      # Ensure all required data is set BEFORE sending the request off to the remote API
      def validate_contents
        missing_elements = self.class.elements.map(&:name).select {|e| !self.respond_to?(e) || self.send(e).nil?}
        raise Exceptions::MissingRequiredElements.new(missing_elements.join(', ')) unless missing_elements.empty?

        missing_attributes = self.class.attributes.map(&:name).select {|a| !self.respond_to?(a) || self.send(a).nil?}
        raise Exceptions::MissingRequiredAttributes.new(missing_attributes.join(', ')) unless missing_attributes.empty?
      end
    
      # We have access to Trufina's XML schema, so we might as well validate against it before we hit their servers
      # http://codeidol.com/other/rubyckbk/XML-and-HTML/Validating-an-XML-Document/
      def validate_against_schema
        lxml = XML::Document.string( self.to_xml )
        lxml.validate(Trufina.schema)
      end
    
    end
  
    # When we receive a TrufinaAccessNotification from Trufina, we can then use
    # the included TNID to receive shared user data (note the TNID is valid for 
    # 14 days) with an InfoRequest.  We receive this notification when the user 
    # changes their info or share permissions, or after we send a TrufinaAccessRequest.
    # 
    # Similar to LoginInfoRequest, but no user interaction.
    class InfoRequest < BaseRequest
      include HappyMapper
      tag 'TrufinaInfoRequest'
      namespace_url API_NAMESPACE_URL
    
      element :pid,   String, :tag => 'PID'
      element :tnid,  String, :tag => 'TNID'
      element :pak,   String, :tag => 'PAK'
    end
  
    # We redirect user to Trufina, they complete registration, Trufina redirects
    # them back to our success url with an attached TLID.  We then have 15 minutes
    # to use this TLID to retreive the shared data with a LoginInfoRequest.
    # 
    # Similar to InfoRequest, but requires user interaction.
    class LoginInfoRequest < BaseRequest
      include HappyMapper
      tag 'TrufinaLoginInfoRequest'
      namespace_url API_NAMESPACE_URL
    
      element :pid,   String, :tag => 'PID'
      element :tlid,   String, :tag => 'TLID'
      element :pak,   String, :tag => 'PAK'
    end
  
    # Once we've completed the login flow and retreived our information,
    # if we want additional information later we ask for it with the
    # AccessRequest.
    # 
    # The AccessResponse will contain a status of "pending" for the
    # additional credentials, and Trufina will notify the user via email
    # that a partner is requesting a new credential.  Once the user grants 
    # permission for that credential, the Partner will be notified via a 
    # AccessNotification.
    class AccessRequest < BaseRequest
      include HappyMapper
      tag 'TrufinaAccessRequest'
      namespace_url API_NAMESPACE_URL
    
      element :pid,   String, :tag => 'PID'
      element :prt,   String, :tag => 'PRT'
      element :pak,   String, :tag => 'PAK'
      element :pur,   String, :tag => 'PUR'

      element :data,  Elements::AccessRequest, :single => true
    end
  
  
    # When we wan to send a user to Trufina to register and/or provide their
    # information and allow us access, we send this to Trufina, who sends us
    # back a PLID we can use to generate the redirect URL to which we should
    # send the user.
    class LoginRequest < BaseRequest
      # TODO -- DOCS UNCLEAR! MAY need a xlmns="" for each of these elements..?
      include HappyMapper
      tag 'TrufinaLoginRequest'
      namespace_url API_NAMESPACE_URL
    
      element :pid,   String, :tag => 'PID'
      element :prt,   String, :tag => 'PRT'
      element :pak,   String, :tag => 'PAK'
    
      element :cancel_url,    String, :tag => 'CancelURL'
      element :success_url,   String, :tag => 'SuccessURL'
      element :failure_url,   String, :tag => 'FailureURL'
    
      element :data,  Elements::AccessRequest, :single => true
      element :seed,  Elements::SeedInfoGroup, :single => true
      
      def initialize *args
        super(args)
        
        # Trufina is brilliant, and they fail if this isn't in the request (even though they don't actually read the value)
        seed.residence_address.timeframe = 'current' if seed && seed.residence_address
      end
    end
  
  end
end
