require 'spec_helper'

describe Immutable do

  it_behaves_like "a tenantable model"

  let(:client) do
    Account.create!(:name => "client")
  end

  let(:another_client) do
    Account.create!(:name => "another client")
  end

  describe "#valid?" do
    before do
      Mongoid::Multitenancy.current_tenant = client
    end

    let(:item) do
      Immutable.new(:title => "title X", :slug => "page-x")
    end

    it_behaves_like "a tenant validator"

    context "when the tenant has not changed" do
      before do
        item.save!
      end

      it 'is valid' do
        item.title = "title X (2)"
        expect(item).to be_valid
      end
    end

    context "when the tenant has changed" do
      before do
        item.save!
        Mongoid::Multitenancy.current_tenant = another_client
      end

      it 'is not valid' do
        item.client = another_client
        expect(item).not_to be_valid
      end
    end
  end
end
