require "spec_helper"

describe Mongoid::Multitenancy do
  let(:client) do
    Account.create!(:name => "client")
  end

  let(:another_client) do
    Account.create!(:name => "another client")
  end

  before do
    Mongoid::Multitenancy.current_tenant = client
  end

  describe ".with_tenant" do
    it "changes temporary the current tenant within the block" do
      Mongoid::Multitenancy.with_tenant(another_client) do
        expect(Mongoid::Multitenancy.current_tenant).to eq another_client
      end
    end

    it "restores the current tenant after the block" do
      Mongoid::Multitenancy.with_tenant(another_client) do ; end
      expect(Mongoid::Multitenancy.current_tenant).to eq client
    end
  end
end
