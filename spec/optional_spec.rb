require 'spec_helper'

describe Optional do

  it_behaves_like "a tenantable model"

  let(:client) { Account.create!(:name => "client") }
  let(:another_client) { Account.create!(:name => "another client") }

  describe ".default_scope" do
    before {
      @itemC = Optional.create!(:title => "title C", :slug => "article-c")
      Mongoid::Multitenancy.with_tenant(client) { @itemX = Optional.create!(:title => "title X", :slug => "article-x", :client => client) }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = Optional.create!(:title => "title Y", :slug => "article-y", :client => another_client) }
    }

    context "with a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = another_client }
      after { Mongoid::Multitenancy.current_tenant = nil }

      it "should filter on the current tenant / free-tenant items" do
        Optional.all.to_a.should =~ [@itemY, @itemC]
      end
    end

    context "without a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = nil }

      it "should not filter on any tenant" do
        Optional.all.to_a.should =~ [@itemC, @itemX, @itemY]
      end
    end
  end

  describe "#delete_all" do
    before {
      @itemC = Optional.create!(:title => "title C", :slug => "article-c")
      Mongoid::Multitenancy.with_tenant(client) { @itemX = Optional.create!(:title => "title X", :slug => "article-x", :client => client) }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = Optional.create!(:title => "title Y", :slug => "article-y", :client => another_client) }
    }

    context "with a current tenant" do
      it "should only delete the current tenant / free-tenant items" do
        Mongoid::Multitenancy.with_tenant(another_client) { Optional.delete_all }
        Optional.all.to_a.should =~ [@itemX]
      end
    end

    context "without a current tenant" do
      it "should delete all the pages" do
        Optional.delete_all
        Optional.all.to_a.should be_empty
      end
    end
  end

  describe "#valid?" do
    after { Mongoid::Multitenancy.current_tenant = nil }

    let(:item) { Optional.new(:title => "title X", :slug => "page-x") }

    it_behaves_like "a tenant validator"

    context "with a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = client }

      it "should not set the client field" do
        item.valid?
        item.client.should be_nil
      end
    end

    context "without a current tenant" do
      it "should not set the client field" do
        item.valid?
        item.client.should be_nil
      end

      it "should be valid" do
        item.should be_valid
      end
    end
  end
end