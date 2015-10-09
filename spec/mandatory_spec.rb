require 'spec_helper'

describe Mandatory do

  it_behaves_like "a tenantable model"
  it { is_expected.to validate_tenant_uniqueness_of(:slug) }

  let(:client) do
    Account.create!(:name => "client")
  end

  let(:another_client) do
    Account.create!(:name => "another client")
  end

  describe ".default_scope" do
    before do
      Mongoid::Multitenancy.with_tenant(client) { @itemX = Mandatory.create!(:title => "title X", :slug => "article-x") }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = Mandatory.create!(:title => "title Y", :slug => "article-y") }
    end

    context "with a current tenant" do
      before do
        Mongoid::Multitenancy.current_tenant = another_client
      end

      it "filters on the current tenant" do
        expect(Mandatory.all.to_a).to match_array [@itemY]
      end
    end

    context "without a current tenant" do
      before do
        Mongoid::Multitenancy.current_tenant = nil
      end

      it "does not filter on any tenant" do
        expect(Mandatory.all.to_a).to match_array [@itemX, @itemY]
      end
    end
  end

  describe "#delete_all" do
    before do
      Mongoid::Multitenancy.with_tenant(client) { @itemX = Mandatory.create!(:title => "title X", :slug => "article-x") }
      Mongoid::Multitenancy.with_tenant(another_client) { @itemY = Mandatory.create!(:title => "title Y", :slug => "article-y") }
    end

    context "with a current tenant" do
      it "only deletes the current tenant" do
        Mongoid::Multitenancy.with_tenant(another_client) { Mandatory.delete_all }
        expect(Mandatory.all.to_a).to match_array [@itemX]
      end
    end

    context "without a current tenant" do
      it "deletes all the items" do
        Mandatory.delete_all
        expect(Mandatory.all.to_a).to be_empty
      end
    end
  end

  describe "#valid?" do
    let(:item) do
      Mandatory.new(:title => "title X", :slug => "page-x")
    end

    it_behaves_like "a tenant validator"

    context "with a current tenant" do
      before do
        Mongoid::Multitenancy.current_tenant = client
      end

      it "sets the client field" do
        item.valid?
        expect(item.client).to eq client
      end

      context "with a uniqueness constraint" do
        let(:duplicate) do
          Mandatory.new(:title => "title Y", :slug => "page-x")
        end

        before do
          item.save!
        end

        it 'does not allow duplicates on the same tenant' do
          expect(duplicate).not_to be_valid
        end

        it 'allow duplicates on a different same tenant' do
          Mongoid::Multitenancy.with_tenant(another_client) do
            expect(duplicate).to be_valid
          end
        end
      end
    end

    context "without a current tenant" do
      it "does not set the client field" do
        expect(item.client).to be_nil
      end

      it "is invalid" do
        expect(item).not_to be_valid
      end
    end
  end
end
