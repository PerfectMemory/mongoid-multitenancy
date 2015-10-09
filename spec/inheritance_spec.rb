require 'spec_helper'

describe 'Inheritance' do
  let(:client) do
    Account.create!(:name => "client")
  end

  before do
    Mongoid::Multitenancy.current_tenant = client
  end

  describe "class" do
    it 'uses inheritance pattern' do
      MutableChild.create!(:title => "title X", :slug => "page-x")
      expect(Mutable.last).to be_a MutableChild
    end

    it 'keeps options' do
      expect(AnotherMutableChild.new(:title => "title X", :slug => "page-x")).to be_valid
    end
  end
end
