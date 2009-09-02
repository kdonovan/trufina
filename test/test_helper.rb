require 'rubygems'
require 'active_support'
require 'active_support/test_case'
require 'ostruct'

# Renders the appropriate template for the specified method call
def render(template_name, template_vars = {})
  template_file = File.join(File.dirname(__FILE__), 'fixtures', 'requests', "#{template_name}.xml")
  raise TrufinaException.new("Unable to find fixture file: #{template_file}") unless File.exists?(template_file)
  
  template_binding_object = OpenStruct.new(template_vars)

  template = ERB.new(File.read(template_file))
  template.result(template_binding_object.get_binding)
end
