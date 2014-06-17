require 'spec_helper'

describe 'tenant' do

  let(:client) do
    Account.create!(:name => "client")
  end

  before do
    Mongoid::Multitenancy.current_tenant = client
  end

  context 'without index: true' do
    it 'does not create an index' do
      Immutable.should_not have_index_for(:client_id => 1)
    end
  end

  context 'with index: true' do
    it 'creates an index' do
      Indexable.should have_index_for(:client_id => 1)
    end
  end

  context 'with full_indexes: true' do
    it 'add the tenant field on each index' do
      Immutable.should have_index_for(:client_id => 1, :title => 1)
    end
  end

  context 'with full_indexes: false' do
    it 'does not add the tenant field on each index' do
      Indexable.should_not have_index_for(:client_id => 1, :title => 1)
    end
  end

end