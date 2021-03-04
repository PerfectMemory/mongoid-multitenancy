require 'spec_helper'

describe 'tenant' do
  let(:client) do
    Account.create!(name: 'client')
  end

  before do
    Mongoid::Multitenancy.current_tenant = client
  end

  describe 'tenant full_indexes option' do
    context 'without index option' do
      it 'does not create an index' do
        expect(IndexableWithoutIndex).not_to have_index_for(tenant_id: 1)
      end
    end

    context 'with index: false' do
      it 'does not create an index' do
        expect(IndexableWithIndexFalse).not_to have_index_for(tenant_id: 1)
      end
    end

    context 'with index: true' do
      it 'creates an index' do
        expect(IndexableWithIndexTrue).to have_index_for(tenant_id: 1)
      end
    end
  end

  describe 'index full_index option' do
    context 'without tenant full_indexes option specified' do
      it 'adds the tenant field on each index' do
        expect(IndexableWithoutFullIndexes).to have_index_for(tenant_id: 1, title: 1)
      end

      it 'adds the tenant field on the index with full_index: true' do
        expect(IndexableWithoutFullIndexes).to have_index_for(tenant_id: 1, name: 1)
      end

      it 'does not add the tenant field on the index with full_index: false' do
        expect(IndexableWithoutFullIndexes).not_to have_index_for(tenant_id: 1, slug: 1)
        expect(IndexableWithoutFullIndexes).to have_index_for(slug: 1)
      end
    end

    context 'with full_indexes: true' do
      it 'adds the tenant field on each index' do
        expect(IndexableWithFullIndexesTrue).to have_index_for(tenant_id: 1, title: 1)
      end

      it 'does not add the tenant field on the index with full_index: false' do
        expect(IndexableWithFullIndexesTrue).not_to have_index_for(tenant_id: 1, name: 1)
        expect(IndexableWithFullIndexesTrue).to have_index_for(name: 1)
      end
    end

    context 'with full_indexes: false' do
      it 'does not add the tenant field on each index' do
        expect(IndexableWithFullIndexesFalse).not_to have_index_for(tenant_id: 1, title: 1)
        expect(IndexableWithFullIndexesFalse).to have_index_for(title: 1)
      end

      it 'does add the tenant field on the index with full_index: true' do
        expect(IndexableWithFullIndexesFalse).to have_index_for(tenant_id: 1, name: 1)
      end
    end
  end
end
