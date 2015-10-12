require 'spec_helper'

describe Optional do

  let(:client) do
    Account.create!(:name => "client")
  end

  let(:another_client) do
    Account.create!(:name => "another client")
  end

  let(:item) do
    Optional.new(:title => "title X", :slug => "page-x")
  end

  it_behaves_like "a tenantable model"
  it { is_expected.to validate_tenant_uniqueness_of(:slug) }

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
    context "with a tenant" do
      before do
        item.client = client
      end

      it 'is valid' do
        expect(item).to be_valid
      end

      context "with a uniqueness constraint" do
        let(:duplicate) do
          Optional.new(:title => "title Y", :slug => "page-x")
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

    context "without a tenant" do
      before do
        item.client = nil
      end

      it 'is valid' do
        expect(item).to be_valid
      end

      context "with a uniqueness constraint" do
        let(:duplicate) do
          Optional.new(:title => "title Y", :slug => "page-x")
        end

        before do
          item.save!
        end

        it 'does not allow duplicates on any client' do
          Mongoid::Multitenancy.with_tenant(client) do
            expect(duplicate).not_to be_valid
          end
        end
      end
    end
  end
end
