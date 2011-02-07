# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{has_constant}
  s.version = "0.4.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["mattbeedle"]
  s.date = %q{2011-02-07}
  s.description = %q{Allows certain fields to be limited to a set of values}
  s.email = %q{mattbeedle@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rvmrc",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "has_constant.gemspec",
    "lib/has_constant.rb",
    "lib/has_constant/orm/active_record.rb",
    "lib/has_constant/orm/mongoid.rb",
    "test/has_constant_test.rb",
    "test/helper.rb",
    "test/unit/orm/active_record_test.rb",
    "test/unit/orm/mongoid_test.rb"
  ]
  s.homepage = %q{http://github.com/mattbeedle/has_constant}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Allows certain fields to be limited to a set of values}
  s.test_files = [
    "test/has_constant_test.rb",
    "test/helper.rb",
    "test/unit/orm/active_record_test.rb",
    "test/unit/orm/mongoid_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<activesupport>, [">= 0"])
    else
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
    end
  else
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
  end
end

