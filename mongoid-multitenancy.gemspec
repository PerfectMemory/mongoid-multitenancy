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

  gem.add_dependency('mongoid', '~> 3')

  gem.add_development_dependency('rake', '~> 10.0')
  gem.add_development_dependency('rspec', '~> 2.12')
  gem.add_development_dependency('yard', '~> 0.8')
  gem.add_development_dependency('mongoid-rspec', '~> 1.5')
  gem.add_development_dependency('database_cleaner', '~> 1.0')
  gem.add_development_dependency('redcarpet', '~> 2.2')
end
