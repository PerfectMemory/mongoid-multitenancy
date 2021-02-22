MODELS = File.join(File.dirname(__FILE__), 'models')

require 'simplecov'
require 'coveralls'
require 'database_cleaner-mongoid'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'rspec'
require 'mongoid'
require 'mongoid-multitenancy'
require 'mongoid-rspec'

require_relative 'support/shared_examples'
require_relative 'support/mongoid_matchers'

Dir["#{MODELS}/*.rb"].each { |f| require f }

Mongoid.configure do |config|
  config.connect_to 'mongoid_multitenancy'
end

Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO

RSpec.configure do |config|
  config.include Mongoid::Matchers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end

  config.before(:each) do
    Mongoid::Multitenancy.current_tenant = nil
  end
end
