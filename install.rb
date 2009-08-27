require 'fileutils'

# Copy over the template config file, unless one already exists
config = File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'trufina.yml')
FileUtils.cp File.join(File.dirname(__FILE__), 'trufina.yml.tpl'), config unless File.exist?(config)
