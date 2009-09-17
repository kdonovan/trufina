# Contains smaller classes (essentially HappyMapper element classes) used to create and
# parse API calls and responses.

class Trufina
  
  # Handle creating a HappyMapper object from array or hash (creating empty nodes as required).
  module AllowCreationFromHash
    
    def initialize(seed_data = {})
      create_nodes(seed_data)

      # Define attributes
      self.class.attributes.each do |attr|
        self.send("#{attr.method_name}=", nil) unless self.send(attr.method_name)
      end
      
      # Define elements
      self.class.attributes.each do |elem|
        self.send("#{elem.method_name}=", nil) unless self.send(elem.method_name)
      end
    end

    protected
    
    def create_nodes(data)
      data.each do |key, value|
        create_node(key, value)
      end
    end
    
    # Handle the actual node creation
    def create_node(name, content = nil)
      return create_nodes(name) if content.nil? && name.is_a?(Hash) # Handle accidentally passing in a full hash
      
      element   = self.class.elements.detect{|e| e.method_name.to_sym == name}
      raise Exceptions::InvalidElement.new("No known element named '#{name}'") unless element || self.respond_to?("#{name}=")
      
      case name
      when Hash then create_nodes(name)
      when Array  then create_empty_nodes(name)
      else
        value = if content.nil?
          make_object?(element) ? element.type.new : ''
        elsif content.is_a?(Array) && (element && !element.options[:single])
          # If elements expects multiple instances, instantiate them all (e.g. StreetAddresses)
          # Note that this assumes the object (only known case is Trufina::Elements::StreetAddress) has a :name element
          out = content.collect do |local_content|
            make_object?(element) ? element.type.new(:name => local_content) : local_content
          end
        else
          make_object?(element) ? element.type.new(content) : content
        end
        
        self.send("#{name}=", value)
      end
    end
    
    # Returns false if the given content is a simple type like a string, and we should just assign it.
    # Returns true if the given content is another HappyMapper class, and we should instantiate the class 
    # rather than merely assigning the value.
    def make_object?(element)
      element && !HappyMapper::Item::Types.include?(element.type)
    end
    
  end

  module Elements
    RESPONSE_XML_ATTRIBUTES = {:state => String, :age => String, :charged => String, :status => String, :errors => String }

    module EasyElementAccess
      
      # Shortcut to collecting any information that's present and available
      def present_and_verified
        yes = {}
        self.class.elements.map(&:method_name).each do |p|
          next unless val = self.send(p)
          element = self.class.elements.detect{|e| e.method_name == p}
          
          if val.respond_to?(:present_and_verified)
            yes[p.to_sym] = val.present_and_verified
          elsif element.options[:single]
            yes[p.to_sym] = val if val.state == 'verified' && val.status == 'present'
          else # street_addresses is an array...
            values = []
            val.each do |array_item|
              values << array_item if array_item.state == 'verified' && array_item.status == 'present'
            end
            yes[p.to_sym] = values
          end
        end
        yes
      end
      
    end
    
    # Encapsulates the various name components Trufina accepts
    class Name
      include AllowCreationFromHash
      include HappyMapper
      include EasyElementAccess
      tag 'Name'
  
      element :prefix,  String, :tag => 'Prefix',               :attributes => RESPONSE_XML_ATTRIBUTES
      element :first,   String, :tag => 'First',                :attributes => RESPONSE_XML_ATTRIBUTES
      element :middle,  String, :tag => 'MiddleName',           :attributes => RESPONSE_XML_ATTRIBUTES
      element :middle_initial, String, :tag => 'MiddleInitial', :attributes => RESPONSE_XML_ATTRIBUTES
      element :last,    String, :tag => 'Surname',              :attributes => RESPONSE_XML_ATTRIBUTES
      element :suffix,  String, :tag => 'Suffix',               :attributes => RESPONSE_XML_ATTRIBUTES
      
      def to_s
        name_parts = self.class.elements.map(&:method_name)
        name_parts.collect {|name_part| self.send(name_part) }.compact.join(' ')
      end
    end
    
    # Encapsulates Trufina's address fields - has multiple street address fields
    class ResidenceAddressResponse
      include AllowCreationFromHash
      include HappyMapper
      include EasyElementAccess
      tag 'ResidenceAddress'

      has_many :street_addresses, String,         :tag => 'StreetAddress',  :attributes => RESPONSE_XML_ATTRIBUTES
      element :city,              String,         :tag => 'City',           :attributes => RESPONSE_XML_ATTRIBUTES
      element :state,             String,         :tag => 'State',          :attributes => RESPONSE_XML_ATTRIBUTES
      element :zip,               String,         :tag => 'PostalCode',     :attributes => RESPONSE_XML_ATTRIBUTES
      attribute :timeframe,       String

      def street_address=(adr)
        self.street_addresses ||= []
        self.street_addresses << adr
      end
      
      def to_s
        [street_addresses[0], street_addresses[1], city, state, zip].compact.join(', ')
      end
    end
    
    # Encapsulates Trufina's address fields - only one street address field
    class ResidenceAddressRequest
      include AllowCreationFromHash
      include HappyMapper
      include EasyElementAccess
      tag 'ResidenceAddress'

      element :street_address,    String,         :tag => 'StreetAddress',  :attributes => RESPONSE_XML_ATTRIBUTES
      element :city,              String,         :tag => 'City',           :attributes => RESPONSE_XML_ATTRIBUTES
      element :state,             String,         :tag => 'State',          :attributes => RESPONSE_XML_ATTRIBUTES
      element :zip,               String,         :tag => 'PostalCode',     :attributes => RESPONSE_XML_ATTRIBUTES
    end


    # Encapsulates all response data Trufina may send back
    class AccessResponseGroup
      include AllowCreationFromHash
      include HappyMapper
      include EasyElementAccess
      tag 'AccessResponse'
  
      element :name,              Name,     :single => true
      # element :birth_date,        Date,     :tag => 'DateOfBirth',    :attributes => RESPONSE_XML_ATTRIBUTES
      # element :birth_country,     String,   :tag => 'CountryOfBirth', :attributes => RESPONSE_XML_ATTRIBUTES
      element :phone,             String,   :tag => 'Phone',          :attributes => RESPONSE_XML_ATTRIBUTES
      element :age,               String,   :tag => 'Age',            :attributes => RESPONSE_XML_ATTRIBUTES
      element :residence_address, ResidenceAddressResponse,           :single => true
      element :ssn,               String,   :tag => 'fullSSN',        :attributes => RESPONSE_XML_ATTRIBUTES
      element :last_4_ssn,        String,   :tag => 'Last4SSN',       :attributes => RESPONSE_XML_ATTRIBUTES
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
      element :age,               String,   :tag => 'Age',            :attributes => {:comparison => String}
      element :residence_address, ResidenceAddressRequest,            :single => true   # If Trufina implemented it, could have timeframe and maxAge attributes
      element :ssn,               String,   :tag => 'fullSSN'
      element :last_4_ssn,        String,   :tag => 'Last4SSN'
    end
    
    # Encapsulates all seed data Trufina accepts
    class SeedInfoGroup
      include AllowCreationFromHash
      include HappyMapper
      tag 'SeedInfo'
      
      element :name,              Name,     :single => true
      element :birth_date,        Date,     :tag => 'DateOfBirth'
      element :birth_country,     String,   :tag => 'CountryOfBirth'
      element :phone,             String,   :tag => 'Phone'
      element :age,               String,   :tag => 'Age'
      element :residence_address, ResidenceAddressResponse,           :single => true
      element :ssn,               String,   :tag => 'fullSSN'
      element :last_4_ssn,        String,   :tag => 'Last4SSN'
    end
    
  end
end
