class Trufina
  RESPONSE_XML_ATTRIBUTES = {:state => String, :age => String, :charged => String, :status => String, :errors => String }
  # ======================
  # = Subsidiary classes =
  # ======================
  class Name
    include HappyMapper
    tag 'Name'
  
    element :prefix,  String, :tag => 'Prefix',               :attributes => RESPONSE_XML_ATTRIBUTES
    element :first,   String, :tag => 'First',                :attributes => RESPONSE_XML_ATTRIBUTES
    element :middle,  String, :tag => 'Middle',               :attributes => RESPONSE_XML_ATTRIBUTES
    element :middle_initial, String, :tag => 'MiddleInitial', :attributes => RESPONSE_XML_ATTRIBUTES
    element :surname, String, :tag => 'Surname',              :attributes => RESPONSE_XML_ATTRIBUTES
    element :suffix,  String, :tag => 'Suffix',               :attributes => RESPONSE_XML_ATTRIBUTES
  end

  class StreetAddress
    include HappyMapper
    tag 'StreetAddress'
    element :name, String, :tag => '.'
  end

  class ResidenceAddress
    include HappyMapper
    tag 'ResidenceAddress'

    has_many :street_addresses, StreetAddress,  :tag => 'StreetAddress',  :attributes => RESPONSE_XML_ATTRIBUTES
    element :city,              String,         :tag => 'City',           :attributes => RESPONSE_XML_ATTRIBUTES
    element :state,             String,         :tag => 'State',          :attributes => RESPONSE_XML_ATTRIBUTES
    element :postal_code,       String,         :tag => 'PostalCode',     :attributes => RESPONSE_XML_ATTRIBUTES
  end


  class AccessResponseGroup
    include HappyMapper
    tag 'AccessResponse'
  
    # TODO -- ensure have all
    element :age,               String,   :tag => 'Age',            :attributes => RESPONSE_XML_ATTRIBUTES
    element :birth_date,        Date,     :tag => 'DateOfBirth',    :attributes => RESPONSE_XML_ATTRIBUTES
    element :birth_country,     String,   :tag => 'CountryOfBirth', :attributes => RESPONSE_XML_ATTRIBUTES
    element :phone,             String,   :tag => 'Phone',          :attributes => RESPONSE_XML_ATTRIBUTES
    element :last_4_ssn,        String,   :tag => 'Last4SSN',       :attributes => RESPONSE_XML_ATTRIBUTES
    element :ssn,               String,   :tag => 'fullSSN',        :attributes => RESPONSE_XML_ATTRIBUTES
    element :name,              Name,     :single => true,          :attributes => RESPONSE_XML_ATTRIBUTES
    element :residence_address, ResidenceAddress, :single => true,  :attributes => RESPONSE_XML_ATTRIBUTES
  end
end