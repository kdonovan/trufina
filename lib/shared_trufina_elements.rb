class Trufina
  # Handle creating a HappyMapper object from Array or hash
  module AllowCreationFromHash
    
    def initialize(seed_data = {})
      seed_data.is_a?(Array) ? create_empty_nodes(seed_data) : create_nodes(seed_data)
    end

    protected
    
    # e.g. Trufina::Name.new([:first, :suffix]) - no values provided, print empty nodes
    #
    #     <Name>
    #       <First/>
    #       <Suffix/>
    #     </Name>
    def create_empty_nodes(nodes)
      nodes.each do |node|
        create_node(node)
      end
    end

    # e.g. Trufina::Name.new({:first => 'Bob', :suffix => 'III'}) - print nodes with values
    # 
    #     <Name>
    #       <First>Bob</First>
    #       <Suffix>III</Suffix>
    #     </Name>
    def create_nodes(nodes)
      nodes.each do |node, content|
        create_node(node, content)
      end
    end
    
    # Handle the actual node creation
    def create_node(name, content = nil)
      case name
      when Array then create_empty_nodes(name)
      when Hash then create_nodes(name)
      else
        element   = self.class.elements.detect{|e| e.method_name.to_sym == name}
        raise InvalidElement.new("No known element named '#{name}'") unless element

        value = if HappyMapper::Item::Types.include?(element.type)
          content ? content : ''
        else 
          content ? element.type.new(content) : element.type.new
        end
        self.send("#{name}=", value)
      end
    end
    
  end

  module Elements
    RESPONSE_XML_ATTRIBUTES = {:state => String, :age => String, :charged => String, :status => String, :errors => String }

    # Encapsulates the various name components Trufina accepts
    class Name
      include AllowCreationFromHash
      include HappyMapper
      tag 'Name'
  
      element :prefix,  String, :tag => 'Prefix',               :attributes => RESPONSE_XML_ATTRIBUTES
      element :first,   String, :tag => 'First',                :attributes => RESPONSE_XML_ATTRIBUTES
      element :middle,  String, :tag => 'MiddleName',           :attributes => RESPONSE_XML_ATTRIBUTES
      element :middle_initial, String, :tag => 'MiddleInitial', :attributes => RESPONSE_XML_ATTRIBUTES
      element :surname, String, :tag => 'Surname',              :attributes => RESPONSE_XML_ATTRIBUTES
      element :suffix,  String, :tag => 'Suffix',               :attributes => RESPONSE_XML_ATTRIBUTES
    end
    
    # Wrapper attempting to allow access to multiple StreetAddress tags per single ResidenceAddress
    class StreetAddress
      include AllowCreationFromHash
      include HappyMapper
      tag 'StreetAddress'
      element :name, String, :tag => '.', :attributes => RESPONSE_XML_ATTRIBUTES
    end

    # Encapsulates Trufina's address fields
    class ResidenceAddress
      include AllowCreationFromHash
      include HappyMapper
      tag 'ResidenceAddress'

      has_many :street_addresses, StreetAddress,  :tag => 'StreetAddress',  :attributes => RESPONSE_XML_ATTRIBUTES
      element :city,              String,         :tag => 'City',           :attributes => RESPONSE_XML_ATTRIBUTES
      element :state,             String,         :tag => 'State',          :attributes => RESPONSE_XML_ATTRIBUTES
      element :postal_code,       String,         :tag => 'PostalCode',     :attributes => RESPONSE_XML_ATTRIBUTES
    end

    # Encapsulates all response data Trufina may send back
    class AccessResponseGroup
      include AllowCreationFromHash
      include HappyMapper
      tag 'AccessResponse'
  
      element :name,              Name,     :single => true,          :attributes => RESPONSE_XML_ATTRIBUTES
      element :birth_date,        Date,     :tag => 'DateOfBirth',    :attributes => RESPONSE_XML_ATTRIBUTES
      element :birth_country,     String,   :tag => 'CountryOfBirth', :attributes => RESPONSE_XML_ATTRIBUTES
      element :phone,             String,   :tag => 'Phone',          :attributes => RESPONSE_XML_ATTRIBUTES
      element :residence_address, ResidenceAddress, :single => true,  :attributes => RESPONSE_XML_ATTRIBUTES
      element :ssn,               String,   :tag => 'fullSSN',        :attributes => RESPONSE_XML_ATTRIBUTES
      element :last_4_ssn,        String,   :tag => 'Last4SSN',       :attributes => RESPONSE_XML_ATTRIBUTES
      element :age,               String,   :tag => 'Age',            :attributes => RESPONSE_XML_ATTRIBUTES
    end

    # Encapsulates all data we can request from Trufina
    class AccessRequest
      include AllowCreationFromHash
      include HappyMapper
      tag 'AccessRequest'
  
      element :name,              Name,     :single => true
      element :birth_date,        Date,     :tag => 'DateOfBirth'
      element :birth_country,     String,   :tag => 'CountryOfBirth'
      element :phone,             String,   :tag => 'Phone'           # If Trufina implemented it, could have timeframe and maxAge attributes
      element :residence_address, ResidenceAddress, :single => true   # If Trufina implemented it, could have timeframe and maxAge attributes
      element :ssn,               String,   :tag => 'fullSSN'
      element :last_4_ssn,        String,   :tag => 'Last4SSN'
      element :age,               String,   :tag => 'Age',            :attributes => {:comparison => String}
    end
    
    # Encapsulates all seed data Trufina accepts
    class SeedInfoGroup
      include AllowCreationFromHash
      include HappyMapper
      tag 'SeedInfo'
      
      element :name,              Name,     :single => true
      element :email,             String,   :single => true
      element :birth_date,        Date,     :tag => 'DateOfBirth'
      element :birth_country,     String,   :tag => 'CountryOfBirth'
      element :phone,             String,   :tag => 'Phone'
      element :residence_address, ResidenceAddress, :single => true
      element :ssn,               String,   :tag => 'fullSSN'
      element :last_4_ssn,        String,   :tag => 'Last4SSN'
      element :age,               String,   :tag => 'Age'
    end
    
  end
end