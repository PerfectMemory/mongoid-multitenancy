require 'spec_helper'

describe OptionalExclude do
  let(:client) do
    Account.create!(name: 'client')
  end

  let(:another_client) do
    Account.create!(name: 'another client')
  end

  let(:item) do
    OptionalExclude.new(title: 'title X', slug: 'page-x')
  end

  it_behaves_like 'a tenantable model'

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
          OptionalExclude.new(title: 'title Y', slug: 'page-x')
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
          OptionalExclude.new(title: 'title Y', slug: 'page-x')
        end

        before do
          item.save!
        end

        it 'allow duplicates on any client' do
          Mongoid::Multitenancy.with_tenant(client) do
            expect(duplicate).to be_valid
          end
        end
      end
    end
  end
end
