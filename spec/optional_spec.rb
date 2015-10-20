require 'spec_helper'

describe Optional do

  let(:client) do
    Account.create!(name: 'client')
  end

  let(:another_client) do
    Account.create!(name: 'another client')
  end

  let(:item) do
    Optional.new(title: 'title X', slug: 'page-x')
  end

  it_behaves_like 'a tenantable model'
  it { is_expected.to validate_tenant_uniqueness_of(:slug) }

  describe '#initialize' do
    context 'within a client context' do
      before do
        Mongoid::Multitenancy.current_tenant = client
      end

      context 'when persisted' do
        before do
          item.client = nil
          item.save!
        end

        it 'does not override the client' do
          item.reload
          expect(Optional.last.client).to be_nil
        end
      end
    end
  end

  describe '.default_scope' do
    let!(:item_a) do
      Mongoid::Multitenancy.with_tenant(client) do
        Optional.create!(title: 'title A', slug: 'article-a')
      end
    end

    let!(:item_b) do
      Mongoid::Multitenancy.with_tenant(another_client) do
        Optional.create!(title: 'title B', slug: 'article-b')
      end
    end

    let!(:shared_item) do
      Optional.create!(title: 'title C', slug: 'article-c')
    end

    context 'with a current tenant' do
      it 'filters on the current tenant / free-tenant items' do
        Mongoid::Multitenancy.with_tenant(another_client) do
          expect(Optional.all.to_a).to match_array [shared_item, item_b]
        end
      end
    end

    context 'without a current tenant' do
      it 'does not filter on any tenant' do
        expect(Optional.all.to_a).to match_array [item_a, item_b, shared_item]
      end
    end
  end

  describe '.shared' do
    let!(:item_a) do
      Mongoid::Multitenancy.with_tenant(client) do
        Optional.create!(title: 'title A', slug: 'article-a')
      end
    end

    let!(:item_b) do
      Mongoid::Multitenancy.with_tenant(another_client) do
        Optional.create!(title: 'title B', slug: 'article-b')
      end
    end

    let!(:shared_item) do
      Optional.create!(title: 'title C', slug: 'article-c')
    end

    it 'returns only the shared items' do
      Mongoid::Multitenancy.with_tenant(another_client) do
        expect(Optional.shared.to_a).to match_array [shared_item]
      end
    end
  end

  describe '.unshared' do
    let!(:item_a) do
      Mongoid::Multitenancy.with_tenant(client) do
        Optional.create!(title: 'title A', slug: 'article-a')
      end
    end

    let!(:item_b) do
      Mongoid::Multitenancy.with_tenant(another_client) do
        Optional.create!(title: 'title B', slug: 'article-b')
      end
    end

    let!(:shared_item) do
      Optional.create!(title: 'title C', slug: 'article-c')
    end

    it 'returns only the shared items' do
      Mongoid::Multitenancy.with_tenant(another_client) do
        expect(Optional.unshared.to_a).to match_array [item_b]
      end
    end
  end

  describe '#delete_all' do
    let!(:item_a) do
      Mongoid::Multitenancy.with_tenant(client) do
        Optional.create!(title: 'title A', slug: 'article-a')
      end
    end

    let!(:item_b) do
      Mongoid::Multitenancy.with_tenant(another_client) do
        Optional.create!(title: 'title B', slug: 'article-b')
      end
    end

    let!(:shared_item) do
      Optional.create!(title: 'title C', slug: 'article-c')
    end

    context 'with a current tenant' do
      it 'only deletes the current tenant / free-tenant items' do
        Mongoid::Multitenancy.with_tenant(another_client) do
          Optional.delete_all
        end

        expect(Optional.all.to_a).to match_array [item_a]
      end
    end

    context 'without a current tenant' do
      it 'deletes all the pages' do
        Optional.delete_all
        expect(Optional.all.to_a).to be_empty
      end
    end
  end

  describe '#valid?' do
    context 'with a tenant' do
      before do
        Mongoid::Multitenancy.current_tenant = client
      end

      it 'is valid' do
        expect(item).to be_valid
      end

      context 'with a uniqueness constraint' do
        let(:duplicate) do
          Optional.new(title: 'title Y', slug: 'page-x')
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

    context 'without a tenant' do
      it 'is valid' do
        expect(item).to be_valid
      end

      context 'with a uniqueness constraint' do
        let(:duplicate) do
          Optional.new(title: 'title Y', slug: 'page-x')
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
