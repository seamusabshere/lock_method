# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lock_method/version"

Gem::Specification.new do |s|
  s.name        = "lock_method"
  s.version     = LockMethod::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/lock_method"
  s.summary     = %q{Lets you lock methods (to memcached, redis, etc.) as though you had a lockfile for each one}
  s.description = %q{Like alias_method, but it's lock_method!}

  s.rubyforge_project = "lock_method"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
  
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'memcached'
  if RUBY_VERSION >= '1.9'
    s.add_development_dependency 'ruby-debug19'
  else
    s.add_development_dependency 'ruby-debug'
  end
end
