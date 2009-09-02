class Trufina
  class Response
    def self.parse(raw_xml)
      noko = Nokogiri::XML(raw_xml)
      
      # Try to find an appropriate local happymapper class
      begin
        klass = "Trufina::#{noko.root.name.gsub('Trufina', '')}".constantize
        response = klass.parse(noko.to_xml)
      rescue
        raise UnknownResponseType.new("Raw XML: \n\n#{noko}")
      end
      
      # Raise exception if we've received an error
      if response.is_a?(Trufina::RequestFailure)
        raise TrufinaResponseException.new("#{response.error.kind}: #{response.error}")
      end
      
      # Otherwise return what we've got
      return response
    end
  end

  
  # =========================================================
  # = High-level Responses -- one for each Trufina response =
  # =========================================================
  # These classes are used to parse responses from the Trufina API.

  class RequestFailure
    include HappyMapper
    tag 'TrufinaRequestFailure'
    
    element :error,   String, :tag => 'Error', :attributes => {:kind => String}
  end

  class AccessNotification
    include HappyMapper
    tag 'TrufinaAccessNotification'
    
    element :prt,   String, :tag => 'PRT'
    element :tnid,  String, :tag => 'TNID'
  end

  class AccessResponse
    include HappyMapper
    tag 'TrufinaAccessResponse'
    
    element :prt,   String, :tag => 'PRT'
    element :data,  Elements::AccessResponseGroup, :single => true
  end

  class InfoResponse
    include HappyMapper
    tag 'TrufinaInfoResponse'
    
    element :prt,   String, :tag => 'PRT'
    element :tnid,  String, :tag => 'TNID'
    element :pur,   String, :tag => 'PUR'
    element :data,  Elements::AccessResponseGroup, :single => true
  end

  class LoginInfoResponse
    include HappyMapper
    tag 'TrufinaLoginInfoResponse'
    
    element :tlid,   String, :tag => 'TLID'
    element :prt,    String, :tag => 'PRT'
    element :pur,    String, :tag => 'PUR'
    element :data,   Elements::AccessResponseGroup, :single => true
  end

  class LoginResponse
    include HappyMapper
    tag 'TrufinaLoginResponse'
    
    element :prt,   String, :tag => 'PRT'
    element :plid,  String, :tag => 'PLID'
  end

end