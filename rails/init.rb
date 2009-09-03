base = File.join(File.dirname(__FILE__), '..')

# Require jimmyz's happymapper to enable to_xml for happymap classes
require 'happymapper'

# Require the rest of the plugin files
require File.join(base, 'lib', 'exceptions.rb')
require File.join(base, 'lib', 'config.rb')
require File.join(base, 'lib', 'elements.rb')
require File.join(base, 'lib', 'requests.rb')
require File.join(base, 'lib', 'responses.rb')
require File.join(base, 'lib', 'trufina.rb')