# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mongoid/multitenancy/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Aymeric Brisse"]
  gem.email         = ["aymeric.brisse@mperfect-memory.com"]
  gem.description   = %q{MultiTenancy with Mongoid}
  gem.summary       = %q{Support of a multi-tenant database with Mongoid}
  gem.homepage      = "https://github.com/PerfectMemory/mongoid-multitenancy"
  gem.license       = 'MIT'
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "mongoid-multitenancy"
  gem.require_paths = ["lib"]
  gem.version       = Mongoid::Multitenancy::VERSION

  gem.add_dependency('mongoid', '>= 4.0')
end
