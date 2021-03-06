# -*- encoding: utf-8 -*-
require File.expand_path('../lib/lock_method/version', __FILE__)

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
  
  s.add_runtime_dependency 'cache', '>=0.2.1'
  s.add_runtime_dependency 'activesupport'
end