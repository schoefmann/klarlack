# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{klarlack}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Max Sch\303\266fmann"]
  s.date = %q{2009-04-24}
  s.email = %q{max@pragmatic-it.de}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "lib/klarlack.rb",
    "lib/varnish/client.rb",
    "lib/varnish/socket_factory.rb",
    "spec/klarlack_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/schoefmax/klarlack}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{ruby client for varnishd's admin interface}
  s.test_files = [
    "spec/klarlack_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
