# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{trufina}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kali Donovan"]
  s.date = %q{2009-09-04}
  s.description = %q{Provides a DSL to easily interact with the XML API offered by Trufina.com, an identity verification company.}
  s.email = %q{kali.donovan@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "MIT-LICENSE",
     "README.rdoc",
     "Rakefile",
     "TODO",
     "VERSION",
     "init.rb",
     "lib/config.rb",
     "lib/elements.rb",
     "lib/exceptions.rb",
     "lib/requests.rb",
     "lib/responses.rb",
     "lib/trufina.rb",
     "rails/init.rb",
     "tasks/trufina_tasks.rake",
     "test/fixtures/requests/access_request.xml",
     "test/fixtures/requests/info_request.xml",
     "test/fixtures/requests/login_info_request.xml",
     "test/fixtures/requests/login_request.xml",
     "test/fixtures/requests/login_request_simple.xml",
     "test/fixtures/responses/access_notification.xml",
     "test/fixtures/responses/access_response.xml",
     "test/fixtures/responses/info_response.xml",
     "test/fixtures/responses/login_info_response.xml",
     "test/fixtures/responses/login_response.xml",
     "test/fixtures/schema.xsd",
     "test/test_helper.rb",
     "test/trufina_test.rb",
     "trufina.gemspec",
     "trufina.yml.template"
  ]
  s.homepage = %q{http://github.com/kdonovan/trufina}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{DSL to easily interact with Trufina's verification API}
  s.test_files = [
    "test/test_helper.rb",
     "test/trufina_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<jimmyz-happymapper>, [">= 0"])
    else
      s.add_dependency(%q<jimmyz-happymapper>, [">= 0"])
    end
  else
    s.add_dependency(%q<jimmyz-happymapper>, [">= 0"])
  end
end
