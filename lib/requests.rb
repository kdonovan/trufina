# # Check for errors. TrufinaRequestFailure is clear, and has errors in the Trufina namespace
# # Unknown TNID error from info_request, on the other hand, has no special root name but has Error 
# # node with no namespace
# def check_for_errors
#   if name == 'TrufinaRequestFailure' || @xml.xpath('//Error').first
#     error = @xml.xpath('//Error').first
#     error ||= @xml.xpath('//xmlns:Error').first # This must be second, because raises exception if no namespace defined
#     raise RequestFailure.new("#{error.attributes['kind']}: #{error.text}")
#   end
# end

# These classes are used to generate requests to the Trufina API.
class Trufina
  
  class Request
    # Virtual class, subclasses implement actual API requests
    attr_accessor :elements, :root_name, :namespace
    DEFAULT_NAMESPACE = 'http://www.trufina.com/truapi/1/0'

    def initialize(ns = :default)
      @root_name = self.class.name.gsub('::', '')
      @namespace = ns == :default ? DEFAULT_NAMESPACE : ns
      @elements = []
    end
    
    def self.element(name, opts = {})
      elem = RequestElement.new(name, opts)
      self << elem
      
    end
    
    def <<(elem)
      return false unless elem.is_a?(RequestElement)
      @elements << elem
      return true
    end
    
    # def to_xml
    #   xml =  [%{<?xml version="1.0" encoding="UTF-8"?>}]
    #   namespace_attrib = namespace.blank? ? '' : %Q{ xmlns="#{namespace}"}
    #   xml << %Q{<#{root_name}#{namespace_attrib}>}
    #   
    #   # Add the elements
    #   elements.each {|elem| xml << elem.to_xml }
    #   
    #   xml << "</#{root_name}>"
    #   xml.join("\n")
    # end
  end
  
  class InfoRequest < Request
  end
  
  
  class RequestElement
    attr_accessor :name, :value, :attributes
    def initialize(name, value, opts = {})
      @name = name
      @tag_name = opts[:tag] || name.camelcase
      @value = value
      @attributes = opts[:attributes] || []
    end
  end
  
  
  
  
  
  
  
  
  
  
  
  
  
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
  # class InfoRequest < TemplateBinding
  #   def initialize(tnid)
  #     super
  #     raise MissingToken.new("No TNID provided") if tnid.blank?
  #     @tnid = tnid
  #   end
  # end

  
  # Helper method for reading in config data
  def self.recursively_symbolize_keys!(hash)
    hash.symbolize_keys!
    hash.values.select{|v| v.is_a? Hash}.each{|h| recursively_symbolize_keys!(h)}
  end
  
  
end