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

shared_examples_for "a tenantable model" do

  it { should belong_to(:client) }
  it { should validate_uniqueness_of(:slug).scoped_to(:client_id) }
  it { should have_index_for(:client_id => 1, :title => 1) }

  let(:client) { Account.create!(:name => "client") }
  let(:another_client) { Account.create!(:name => "another client") }

  describe ".initialize" do
    before { Mongoid::Multitenancy.current_tenant = client }
    after { Mongoid::Multitenancy.current_tenant = nil }

    it "should set the client field" do
      described_class.new.client.should eq client
    end
  end

end

describe Page do

  it_behaves_like "a tenantable model"

  it { should_not validate_presence_of(:client_id) }

  let(:client) { Account.create!(:name => "client") }
  let(:another_client) { Account.create!(:name => "another client") }

  describe ".default_scope" do
    before {
      @itemC = described_class.create!(:title => "title C", :slug => "article-c")
      Mongoid::Multitenancy.with_tenant(client) { @itemX = described_class.create!(:title => "title X", :slug => "article-x") }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = described_class.create!(:title => "title Y", :slug => "article-y") }
    }

    context "with a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = another_client }
      after { Mongoid::Multitenancy.current_tenant = nil }

      it "should filter on the current tenant / free-tenant items" do
        described_class.all.to_a.should =~ [@itemY, @itemC]
      end
    end

    context "without a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = nil }

      it "should not filter on any tenant" do
        described_class.all.to_a.should =~ [@itemC, @itemX, @itemY]
      end
    end
  end

  describe "#delete_all" do
    before {
      @itemC = described_class.create!(:title => "title C", :slug => "article-c")
      Mongoid::Multitenancy.with_tenant(client) { @itemX = described_class.create!(:title => "title X", :slug => "article-x") }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = described_class.create!(:title => "title Y", :slug => "article-y") }
    }

    context "with a current tenant" do
      it "should only delete the current tenant / free-tenant items" do
        Mongoid::Multitenancy.with_tenant(another_client) { described_class.delete_all }
        described_class.all.to_a.should =~ [@itemX]
      end
    end

    context "without a current tenant" do
      it "should delete all the pages" do
        described_class.delete_all
        described_class.all.to_a.should be_empty
      end
    end
  end

end

describe Article do

  it_behaves_like "a tenantable model"

  it { should validate_presence_of(:client_id) }

  let(:client) { Account.create!(:name => "client") }
  let(:another_client) { Account.create!(:name => "another client") }

  describe ".default_scope" do
    before {
      Mongoid::Multitenancy.with_tenant(client) { @itemX = described_class.create!(:title => "title X", :slug => "article-x") }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = described_class.create!(:title => "title Y", :slug => "article-y") }
    }

    context "with a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = another_client }
      after { Mongoid::Multitenancy.current_tenant = nil }

      it "should filter on the current tenant" do
        described_class.all.to_a.should =~ [@itemY]
      end
    end

    context "without a current tenant" do
      before { Mongoid::Multitenancy.current_tenant = nil }

      it "should not filter on any tenant" do
        described_class.all.to_a.should =~ [@itemX, @itemY]
      end
    end
  end

  describe "#valid?" do
    before { Mongoid::Multitenancy.current_tenant = client }
    after { Mongoid::Multitenancy.current_tenant = nil }

    let(:article) { Article.create!(:title => "title X", :slug => "article-x") }

    context "when the tenant has not changed" do
      it 'should be valid' do
        article.title = "title X (2)"
        article.should be_valid
      end
    end

    context "when the tenant has changed" do
      it 'should be invalid' do
        article.title = "title X (2)"
        article.client = another_client
        article.should_not be_valid
      end
    end

  end

  describe "#delete_all" do
    before {
      Mongoid::Multitenancy.with_tenant(client) { @itemX = described_class.create!(:title => "title X", :slug => "article-x") }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = described_class.create!(:title => "title Y", :slug => "article-y") }
    }

    context "with a current tenant" do
      it "should only delete the current tenant articles" do
        Mongoid::Multitenancy.with_tenant(another_client) { described_class.delete_all }
        described_class.all.to_a.should =~ [@itemX]
      end
    end

    context "without a current tenant" do
      it "should delete all the articles" do
        described_class.delete_all
        described_class.all.to_a.should be_empty
      end
    end
  end

end
