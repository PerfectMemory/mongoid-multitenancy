$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
MODELS = File.join(File.dirname(__FILE__), "models")

require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'mongoid'
require 'mongoid/multitenancy'
require 'database_cleaner'
require 'mongoid-rspec'

Dir["#{MODELS}/*.rb"].each { |f| require f }

Mongoid.configure do |config|
  config.connect_to "mongoid_multitenancy"
end

Mongoid.logger = Logger.new($stdout)

DatabaseCleaner.orm = "mongoid"

RSpec.configure do |config|
  config.include Mongoid::Matchers

  config.before(:all) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
