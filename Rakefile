require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "trufina"
    gem.summary = %Q{DSL to easily interact with Trufina's verification API}
    gem.description = %Q{Provides a DSL to easily interact with the XML API offered by Trufina.com, an identity verification company.}
    gem.email = "kali.donovan@gmail.com"
    gem.homepage = "http://github.com/kdonovan/trufina"
    gem.authors = ["Kali Donovan"]
    gem.add_dependency "kdonovan-happymapper"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the trufina plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the trufina plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Trufina API'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.exclude('init.rb')
  rdoc.rdoc_files.exclude('rails/init.rb')
end

# gem 'darkfish-rdoc'
# require 'darkfish-rdoc'
# 
# Rake::RDocTask.new(:darkfish) do |rdoc|
#   rdoc.title    = "Trufina API"
#   rdoc.rdoc_files.include 'README.rdoc'
# 
#   rdoc.options += [
#     '-SHN',
#     '-f', 'darkfish',  # This is the important bit
#   ]
# end
