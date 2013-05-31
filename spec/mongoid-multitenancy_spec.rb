require "spec_helper"

describe Mongoid::Multitenancy do
  let(:client) { Account.create!(:name => "client") }
  let(:another_client) { Account.create!(:name => "another client") }

  before { Mongoid::Multitenancy.current_tenant = client }
  after { Mongoid::Multitenancy.current_tenant = nil }

  describe ".with_tenant" do
    it "should change temporary the current tenant within the block" do
      Mongoid::Multitenancy.with_tenant(another_client) do
        Mongoid::Multitenancy.current_tenant.should == another_client
      end
    end

    it "should have restored the current tenant after the block" do
      Mongoid::Multitenancy.with_tenant(another_client) do ; end
      Mongoid::Multitenancy.current_tenant.should == client
    end
  end
end