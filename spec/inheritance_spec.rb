require 'spec_helper'

describe 'Inheritance' do

  let(:client) { Account.create!(:name => "client") }

  describe "class" do
    it 'should use inheritance pattern' do
      MutableChild.create!(:title => "title X", :slug => "page-x")
      expect(Mutable.last).to be_a MutableChild
    end

    it 'should keep options' do
      AnotherMutableChild.new(:title => "title X", :slug => "page-x").should be_valid
    end
  end
end
