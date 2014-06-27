require 'spec_helper'

describe Mandatory do

  it_behaves_like "a tenantable model"

  let(:client) { Account.create!(:name => "client") }
  let(:another_client) { Account.create!(:name => "another client") }

  describe ".default_scope" do
    before {
      Mongoid::Multitenancy.with_tenant(client) { @itemX = Mandatory.create!(:title => "title X", :slug => "article-x") }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = Mandatory.create!(:title => "title Y", :slug => "article-y") }
    }

    context "with a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = another_client }
      after { Mongoid::Multitenancy.current_tenant = nil }

      it "should filter on the current tenant" do
        Mandatory.all.to_a.should =~ [@itemY]
      end
    end

    context "with multiple scoping tenants" do
      before { Mongoid::Multitenancy.set_tenants client, another_client  }
      after { Mongoid::Multitenancy.current_tenant = nil }

      it "should filter on all scoping tenants" do
        Mandatory.all.to_a.should =~ [@itemX, @itemY]
      end
    end

    context "without a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = nil }

      it "should not filter on any tenant" do
        Mandatory.all.to_a.should =~ [@itemX, @itemY]
      end
    end
  end

  describe "#delete_all" do
    before {
      Mongoid::Multitenancy.with_tenant(client) { @itemX = Mandatory.create!(:title => "title X", :slug => "article-x") }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = Mandatory.create!(:title => "title Y", :slug => "article-y") }
    }

    context "with a current tenant" do
      it "should only delete the current tenant" do
        Mongoid::Multitenancy.with_tenant(another_client) { Mandatory.delete_all }
        Mandatory.all.to_a.should =~ [@itemX]
      end
    end

    context "with multiple scoping tenants" do
      before { Mongoid::Multitenancy.set_tenants client, another_client  }
      after { Mongoid::Multitenancy.current_tenant = nil }

      it "should delete for all scoping tenants" do
        Mandatory.delete_all
        Mandatory.all.to_a.should be_empty
      end
    end

    context "without a current tenant" do
      it "should delete all the items" do
        Mandatory.delete_all
        Mandatory.all.to_a.should be_empty
      end
    end
  end

  describe "#valid?" do
    after { Mongoid::Multitenancy.current_tenant = nil }

    let(:item) { Mandatory.new(:title => "title X", :slug => "page-x") }

    it_behaves_like "a tenant validator"

    context "with a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = client }

      it "should set the client field" do
        item.valid?
        item.client.should eq client
      end
    end

    context "without a current tenant" do
      it "should not set the client field" do
        item.valid?
        item.client.should be_nil
      end

      it "should be invalid" do
        item.should_not be_valid
      end
    end
  end
end
