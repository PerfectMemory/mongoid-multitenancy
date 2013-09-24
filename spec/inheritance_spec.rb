require 'spec_helper'

describe 'Inheritance' do

  let(:client) { Account.create!(:name => "client") }

  describe "class" do
    before do
      Mongoid::Multitenancy.current_tenant = client
      MutableChild.create :title => "title X", :slug => "page-x"
    end
    after { Mongoid::Multitenancy.current_tenant = nil }

    it 'should be valid' do
      expect(Mutable.last).to be_a MutableChild
    end
  end
end
