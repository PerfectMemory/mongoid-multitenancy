require 'spec_helper'

describe NoScopable do
  it_behaves_like 'a tenantable model' do
    let(:client) do
      Account.create!(name: 'client')
    end

    let(:another_client) do
      Account.create!(name: 'another client')
    end

    let(:item) do
      NoScopable.new(title: 'title X', slug: 'page-x')
    end
  end

  describe '.shared' do
    it 'is not defined' do
      expect(NoScopable).not_to respond_to(:shared)
    end
  end

  describe '.unshared' do
    it 'is not defined' do
      expect(NoScopable).not_to respond_to(:unshared)
    end
  end
end
