require 'spec_helper'

describe MutableChild do
  let(:client) do
    Account.create!(name: 'client')
  end

  let(:another_client) do
    Account.create!(name: 'another client')
  end

  let(:item) do
    MutableChild.new(title: 'title X', slug: 'page-x')
  end

  it_behaves_like 'a tenantable model'

  describe '#valid?' do
    before do
      Mongoid::Multitenancy.current_tenant = client
    end

    context 'when the tenant has not changed' do
      before do
        item.save!
      end

      it 'is valid' do
        item.title = 'title X (2)'
        expect(item).to be_valid
      end
    end

    context 'when the tenant has changed' do
      before do
        item.save!
        Mongoid::Multitenancy.current_tenant = another_client
      end

      it 'is valid' do
        item.tenant = another_client
        expect(item).to be_valid
      end
    end
  end
end
