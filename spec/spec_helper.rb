MODELS = File.join(File.dirname(__FILE__), "models")

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'rspec'
require 'mongoid'
require 'mongoid-multitenancy'
require 'database_cleaner'
require 'mongoid-rspec'

require_relative 'support/mongoid'
require_relative 'support/shared_examples'

Dir["#{MODELS}/*.rb"].each { |f| require f }

Mongoid.configure do |config|
  config.connect_to "mongoid_multitenancy"
end

Mongoid.logger = Logger.new($stdout)

DatabaseCleaner.orm = "mongoid"

RSpec.configure do |config|
  config.include Mongoid::Matchers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Mongoid::Multitenancy.current_tenant = nil
  end
end
