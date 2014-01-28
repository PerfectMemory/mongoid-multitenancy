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

shared_examples_for "a tenantable model" do

  it { should belong_to(:client) }
  it { should validate_uniqueness_of(:slug).scoped_to(:client_id) }
  it { should have_index_for(:client_id => 1, :title => 1) }

end

shared_examples_for "a tenant validator" do
  context "within a client context" do
    before { Mongoid::Multitenancy.current_tenant = client }

    context "with the client id" do
      before { item.client = client }

      it "should be valid" do
        item.should be_valid
      end
    end

    context "with another client id" do
      before { item.client = another_client }

      it "should be invalid" do
        item.should_not be_valid
      end
    end
  end

  context "without a client context" do
    before { Mongoid::Multitenancy.current_tenant = nil }

    context "with the client id" do
      before { item.client = client }

      it "should be valid" do
        item.should be_valid
      end
    end

    context "with another client id" do
      before { item.client = another_client }

      it "should be valid" do
        item.should be_valid
      end
    end
  end
end