require 'spec_helper'

describe Optional do

  it_behaves_like "a tenantable model"
  it { is_expected.to validate_uniqueness_of(:slug) }

  let(:client) do
    Account.create!(:name => "client")
  end

  let(:another_client) do
    Account.create!(:name => "another client")
  end

  describe ".default_scope" do
    before do
      @itemC = Optional.create!(:title => "title C", :slug => "article-c")
      Mongoid::Multitenancy.with_tenant(client) { @itemX = Optional.create!(:title => "title X", :slug => "article-x", :client => client) }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = Optional.create!(:title => "title Y", :slug => "article-y", :client => another_client) }
    end

    context "with a current tenant" do
      before do
        Mongoid::Multitenancy.current_tenant = another_client
      end

      it "filters on the current tenant / free-tenant items" do
        expect(Optional.all.to_a).to match_array [@itemY, @itemC]
      end
    end

    context "without a current tenant" do
      before do
        Mongoid::Multitenancy.current_tenant = nil
      end

      it "does not filter on any tenant" do
        expect(Optional.all.to_a).to match_array [@itemC, @itemX, @itemY]
      end
    end
  end

  describe "#delete_all" do
    before do
      @itemC = Optional.create!(:title => "title C", :slug => "article-c")
      Mongoid::Multitenancy.with_tenant(client) { @itemX = Optional.create!(:title => "title X", :slug => "article-x", :client => client) }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = Optional.create!(:title => "title Y", :slug => "article-y", :client => another_client) }
    end

    context "with a current tenant" do
      it "only deletes the current tenant / free-tenant items" do
        Mongoid::Multitenancy.with_tenant(another_client) { Optional.delete_all }
        expect(Optional.all.to_a).to match_array [@itemX]
      end
    end

    context "without a current tenant" do
      it "deletes all the pages" do
        Optional.delete_all
        expect(Optional.all.to_a).to be_empty
      end
    end
  end

  describe "#valid?" do
    let(:item) do
      Optional.new(:title => "title X", :slug => "page-x")
    end

    it_behaves_like "a tenant validator"

    context "with a current tenant" do
      before do
        Mongoid::Multitenancy.current_tenant = client
      end

      it "does not set the client field" do
        item.valid?
        expect(item.client).to be_nil
      end
    end

    context "without a current tenant" do
      it "does not set the client field" do
        item.valid?
        expect(item.client).to be_nil
      end

      it "is valid" do
        expect(item).to be_valid
      end
    end
  end
end
