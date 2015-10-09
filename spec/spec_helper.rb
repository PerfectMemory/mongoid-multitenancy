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
require 'mongoid-rspec'

if Mongoid::VERSION.start_with? '5'
  Mongo::Logger.logger.level = ::Logger::FATAL
elsif Mongoid::VERSION.start_with? '4'
  Moped.logger = nil
end

require_relative 'support/shared_examples'
require_relative 'support/database_cleaner'
require_relative 'support/mongoid_matchers'

Dir["#{MODELS}/*.rb"].each { |f| require f }

Mongoid.configure do |config|
  config.connect_to "mongoid_multitenancy"
end

Mongoid.logger = nil

RSpec.configure do |config|
  config.include Mongoid::Matchers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end

  config.after(:each) do
    Mongoid::Multitenancy.current_tenant = nil
  end
end
