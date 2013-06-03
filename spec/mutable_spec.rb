require 'spec_helper'

describe Mutable do

  it_behaves_like "a tenantable model"

  let(:client) { Account.create!(:name => "client") }
  let(:another_client) { Account.create!(:name => "another client") }

  describe "#valid?" do
    before { Mongoid::Multitenancy.current_tenant = client; }
    after { Mongoid::Multitenancy.current_tenant = nil }

    let(:item) { Mutable.new(:title => "title X", :slug => "page-x") }

    it_behaves_like "a tenant validator"

    context "when the tenant has not changed" do
      before { item.save! }
      it 'should be valid' do
        item.title = "title X (2)"
        item.should be_valid
      end
    end

    context "when the tenant has changed" do
      before { item.save!; Mongoid::Multitenancy.current_tenant = another_client }
      it 'should be valid' do
        item.client = another_client
        item.should be_valid
      end
    end
  end
end