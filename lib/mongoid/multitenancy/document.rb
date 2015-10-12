module Mongoid
  module Multitenancy
    module Document
      extend ActiveSupport::Concern

      module ClassMethods
        attr_accessor :tenant_field, :tenant_options

        MULTITENANCY_OPTIONS = [:optional, :immutable, :full_indexes, :index]

        def tenant(association = :account, options = {})
          options = { full_indexes: true, immutable: true }.merge(options)
          assoc_options, multitenant_options = build_options(options)

          # Setup the association between the class and the tenant class
          belongs_to association, assoc_options

          # Get the tenant model and its foreign key
          self.tenant_field = reflect_on_association(association).foreign_key
          self.tenant_options = multitenant_options

          # Validates the tenant field
          validates_tenancy_of tenant_field, multitenant_options

          # Set the default_scope to scope to current tenant
          default_scope lambda {
            if Multitenancy.current_tenant
              if multitenant_options[:optional]
                where(self.tenant_field.to_sym.in => [Multitenancy.current_tenant.id, nil])
              else
                where(self.tenant_field => Multitenancy.current_tenant.id)
              end
            else
              where(nil)
            end
          }

          # Apply the default value when the default scope is complex (optional tenant)
          after_initialize lambda {
            if Multitenancy.current_tenant and send(association.to_sym).nil?
              send "#{association}=".to_sym, Multitenancy.current_tenant
            end
          }

          self.define_singleton_method(:inherited) do |child|
            child.tenant association, options
            super(child)
          end

          if multitenant_options[:index]
            index({self.tenant_field => 1}, { background: true })
          end
        end

        # Validates whether or not a field is unique against the documents in the
        # database.
        #
        # @example
        #
        #   class Person
        #     include Mongoid::Document
        #     include Mongoid::Multitenancy::Document
        #     field :title
        #
        #     validates_tenant_uniqueness_of :title
        #   end
        #
        # @param [ Array ] *args The arguments to pass to the validator.
        def validates_tenant_uniqueness_of(*args)
          validates_with(TenantUniquenessValidator, _merge_attributes(args))
        end

        # Validates whether or not a tenant field is correct.
        #
        # @example Define the tenant validator
        #
        #   class Person
        #     include Mongoid::Document
        #     include Mongoid::Multitenancy::Document
        #     field :title
        #     tenant :client
        #
        #     validates_tenant_of :client
        #   end
        #
        # @param [ Array ] *args The arguments to pass to the validator.
        def validates_tenancy_of(*args)
          validates_with(TenancyValidator, _merge_attributes(args))
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

        # @private
        def build_options(options)
          assoc_options = {}
          multitenant_options = {}

          options.each do |k, v|
            if MULTITENANCY_OPTIONS.include?(k)
              multitenant_options[k] = v
            else
              assoc_options[k] = v
            end
          end

          [assoc_options, multitenant_options]
        end
      end
    end
  end
end
