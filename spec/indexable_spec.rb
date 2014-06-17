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

end