module Mongoid
  module Multitenancy
    module Document
      extend ActiveSupport::Concern

      included do
        private

        # Check that the tenant foreign key field has not been changed once the object has been persisted
        def check_tenant_immutability
          # We check that the tenant has changed and that the old was not nil to avoid after_create callbacks issues.
          # Indeed in this case, even if the flag is set to persisted, changes have not yet been reset.
          if attribute_changed?(self.class.tenant_field) and attribute_was(self.class.tenant_field)
            self.errors.add(self.class.tenant_field, 'is immutable and cannot be updated' )
          end
        end
      end

      module ClassMethods
        # Access to the tenant field
        attr_reader :tenant_field

        def tenant(association = :account, options={})
          # Setup the association between the class and the tenant class
          # TODO: should index this association if no other indexes are defined => , index: true
          belongs_to association, options

          # Get the tenant model and its foreign key
          fkey = reflect_on_association(association).foreign_key
          @tenant_field = fkey

          # Validates the presence of the association key
          validates_presence_of fkey

          # Set the current_tenant on newly created objects
          after_initialize lambda { |m| m.send "#{association}=".to_sym, Multitenancy.current_tenant if Multitenancy.current_tenant ; true }

          # Rewrite accessors to make tenant foreign_key/association immutable
          validate :check_tenant_immutability, :on => :update

          # Set the default_scope to scope to current tenant
          default_scope lambda {
            where(Multitenancy.current_tenant ? { self.tenant_field => Multitenancy.current_tenant.id } : nil)
          }
        end

        # Redefine 'validates_with' to add the tenant scope when using a UniquenessValidator
        def validates_with(*args, &block)
          if args.first == Validations::UniquenessValidator
            args.last[:scope] = Array(args.last[:scope]) << self.tenant_field
          end
          super(*args, &block)
        end

        # Redefine 'index' to include the tenant field in first position
        def index(spec, options = nil)
          spec = { self.tenant_field => 1 }.merge(spec)
          super(spec, options)
        end

        # Redefine 'delete_all' to take in account the default scope
        def delete_all(conditions = nil)
          self.where(conditions).delete
        end
      end
    end
  end
end
