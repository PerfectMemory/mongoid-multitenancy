require 'spec_helper'

describe ConditionalUniqueness do
  let(:client) do
    Account.create!(name: 'client')
  end

  let(:another_client) do
    Account.create!(name: 'another client')
  end

  let(:item) do
    ConditionalUniqueness.new(approved: true, slug: 'page-x')
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

      context 'with a duplicate on the constraint' do
        let(:duplicate) do
          ConditionalUniqueness.new(approved: true, slug: 'page-x')
        end

        before do
          item.save!
        end

        it 'is not valid' do
          expect(duplicate).not_to be_valid
        end

        context 'with a duplicate outside the conditions' do
          before do
            item.update(approved: false)
          end

          it 'is valid' do
            expect(duplicate).to be_valid
          end
        end

        context 'with a different tenant' do
          it 'is valid' do
            Mongoid::Multitenancy.with_tenant(another_client) do
              expect(duplicate).to be_valid
            end
          end
        end
      end
    end
  end
end
