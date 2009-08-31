class Trufina
  
  # =========================================================
  # = High-level Responses -- one for each Trufina response =
  # =========================================================
  # These classes are used to parse responses from the Trufina API.

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
    element :data,  AccessResponseGroup, :single => true
  end

  class InfoResponse
    include HappyMapper
    tag 'TrufinaInfoResponse'
    
    element :prt,   String, :tag => 'PRT'
    element :tnid,  String, :tag => 'TNID'
    element :pur,   String, :tag => 'PUR'
    element :data,  AccessResponseGroup, :single => true
  end

  class LoginInfoResponse
    include HappyMapper
    tag 'TrufinaLoginInfoResponse'
    
    element :tlid,   String, :tag => 'TLID'
    element :prt,    String, :tag => 'PRT'
    element :pur,    String, :tag => 'PUR'
    element :data,   AccessResponseGroup, :single => true
  end

  class LoginResponse
    include HappyMapper
    tag 'TrufinaLoginResponse'
    
    element :prt,   String, :tag => 'PRT'
    element :plid,  String, :tag => 'PLID'
  end

end


__END__
require 'nokogiri'
xml = Nokogiri::XML(Trufina.read('info_response')).to_xml
a = Trufina::InfoResponse.parse(xml, :single => true)
