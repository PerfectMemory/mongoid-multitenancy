module Mongoid
  module Multitenancy
    module Document
      extend ActiveSupport::Concern

      module ClassMethods
        attr_accessor :tenant_field, :tenant_options

        MULTITENANCY_OPTIONS = [:optional, :immutable, :full_indexes, :index]

        def tenant(association = :account, options = {})
          options = { full_indexes: true, immutable: true }.merge(options)

          # Setup the association between the class and the tenant class
          belongs_to association, extract_association_options(options)

          # Get the tenant model and its foreign key
          self.tenant_field = reflect_on_association(association).foreign_key
          self.tenant_options = extract_tenant_options(options)

          # Validates the tenant field
          validates tenant_field, tenant: options

          # Set the default_scope to scope to current tenant
          default_scope lambda {
            if Multitenancy.current_tenant
              if options[:optional]
                where(self.tenant_field.to_sym.in => [Multitenancy.current_tenant.id, nil])
              else
                where(self.tenant_field => Multitenancy.current_tenant.id)
              end
            else
              where(nil)
            end
          }

          self.define_singleton_method(:inherited) do |child|
            child.tenant association, options
            super(child)
          end

          if options[:index]
            index({self.tenant_field => 1}, { background: true })
          end
        end

        # Redefine 'validates_with' to add the tenant scope when using a UniquenessValidator
        def validates_with(*args, &block)
          if !self.tenant_options[:optional]
            validator = if Mongoid::Multitenancy.mongoid4?
              Validatable::UniquenessValidator
            else
              Validations::UniquenessValidator
            end

            if args.first.ancestors.include?(validator)
              args.last[:scope] = Array(args.last[:scope]) << self.tenant_field
            end
          end

          super(*args, &block)
        end

        # Redefine 'index' to include the tenant field in first position
        def index(spec, options = nil)
          spec = { self.tenant_field => 1 }.merge(spec) if self.tenant_options[:full_indexes]
          super(spec, options)
        end

        # Redefine 'delete_all' to take in account the default scope
        def delete_all(conditions = nil)
          scoped.where(conditions).delete
        end

        private

        def extract_association_options(options)
          new_options = {}

          options.each do |k, v|
            new_options[k] = v unless MULTITENANCY_OPTIONS.include?(k)
          end

          new_options
        end

        def extract_tenant_options(options)
          new_options = {}

          options.each do |k, v|
            new_options[k] = v if MULTITENANCY_OPTIONS.include?(k)
          end

          new_options
        end
      end
    end
  end
end
