class Trufina
  class Response
    # Given returned Trufina XML, instantiate the proper HappyMapper wrapper.
    # 
    # (Note that this does not perform any error checking beyond unknown 
    # root node name -- the higher level error checking is handled in the 
    # Trufina.parseFromTrufina method)
    def self.parse(raw_xml)
      noko = Nokogiri::XML(raw_xml)
      
      if Trufina::Config.debug?
        puts "Received XML:\n\n"
        puts noko.to_xml
        puts "\n\n"
      end
      
      # Try to find an appropriate local happymapper class
      begin
        klass = "Trufina::#{noko.root.name.gsub('Trufina', '')}".constantize
        return klass.parse(noko.to_xml)
      rescue
        raise UnknownResponseType.new("Raw XML: \n\n#{noko}")
      end
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
    element :error, String, :tag => 'Error'
  end

  class InfoResponse
    include HappyMapper
    tag 'TrufinaInfoResponse'
    
    element :prt,   String, :tag => 'PRT'
    element :tnid,  String, :tag => 'TNID'
    element :pur,   String, :tag => 'PUR'
    element :data,  Elements::AccessResponseGroup, :single => true
    element :error, String, :tag => 'Error'
  end

  class LoginInfoResponse
    include HappyMapper
    tag 'TrufinaLoginInfoResponse'
    
    element :tlid,   String, :tag => 'TLID'
    element :prt,    String, :tag => 'PRT'
    element :pur,    String, :tag => 'PUR'
    element :data,   Elements::AccessResponseGroup, :single => true
    element :error, String, :tag => 'Error'
  end

  class LoginResponse
    include HappyMapper
    tag 'TrufinaLoginResponse'
    
    element :prt,   String, :tag => 'PRT'
    element :plid,  String, :tag => 'PLID'
    element :error, String, :tag => 'Error'
  end

end