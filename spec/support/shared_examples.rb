shared_examples_for "a tenantable model" do

  it { is_expected.to belong_to(:client) }
  it { is_expected.to have_index_for(:client_id => 1, :title => 1) }

end

shared_examples_for "a tenant validator" do
  context "within a client context" do
    before do
      Mongoid::Multitenancy.current_tenant = client
    end

    context "with the client id" do
      before do
        item.client = client
      end

      it "is valid" do
        expect(item).to be_valid
      end
    end

    context "with another client id" do
      before do
        item.client = another_client
      end

      it "is not valid" do
        expect(item).not_to be_valid
      end
    end
  end

  context "without a client context" do
    before do
      Mongoid::Multitenancy.current_tenant = nil
    end

    context "with the client id" do
      before do
        item.client = client
      end

      it "is valid" do
        expect(item).to be_valid
      end
    end

    context "with another client id" do
      before do
        item.client = another_client
      end

      it "is valid" do
        expect(item).to be_valid
      end
    end
  end
end
