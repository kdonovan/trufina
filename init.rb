# Include hook code here
base = File.dirname(__FILE__)


# TODO - require jimmyz's happymapper
require 'happymapper'

# Require the rest of the plugin files
require File.join(base, 'lib', 'exceptions.rb')
require File.join(base, 'lib', 'config.rb')
require File.join(base, 'lib', 'shared_trufina_elements.rb')
require File.join(base, 'lib', 'requests.rb')
require File.join(base, 'lib', 'responses.rb')
require File.join(base, 'lib', 'trufina.rb')