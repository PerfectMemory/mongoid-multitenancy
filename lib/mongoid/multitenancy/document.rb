module Mongoid
  module Multitenancy
    module Document
      extend ActiveSupport::Concern

      module ClassMethods
        attr_accessor :tenant_field, :tenant_options

        # List of authorized options
        MULTITENANCY_OPTIONS = [:optional, :immutable, :full_indexes, :index]

        # Defines the tenant field for the document.
        #
        # @example Define a tenant.
        #   tenant :client, optional: false, immutable: true, full_indexes: true
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        #   All the belongs_to options are allowed plus the following ones:
        #
        # @option options [ Boolean ] :full_indexes If true the tenant field
        #   will be added for each index.
        # @option options [ Boolean ] :immutable If true changing the tenant
        #   wil raise an Exception.
        # @option options [ Boolean ] :optional If true allow the document
        #   to be shared among all the tenants.
        #
        # @return [ Field ] The generated field
        def tenant(association = :account, options = {})
          options = { full_indexes: true, immutable: true }.merge!(options)
          assoc_options, multitenant_options = build_options(options)

          # Setup the association between the class and the tenant class
          belongs_to association, assoc_options

          # Get the tenant model and its foreign key
          self.tenant_field = reflect_on_association(association).foreign_key
          self.tenant_options = multitenant_options

          # Validates the tenant field
          validates_tenancy_of tenant_field, multitenant_options

          define_default_scope
          define_initializer association
          define_inherited association, options
          define_index if multitenant_options[:index]
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
          if tenant_options[:full_indexes]
            spec = { tenant_field => 1 }.merge(spec)
          end

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

        # @private
        #
        # Define the after_initialize
        def define_initializer(association)
          # Apply the default value when the default scope is complex (optional tenant)
          after_initialize lambda {
            if Multitenancy.current_tenant && send(association.to_sym).nil? && new_record?
              send "#{association}=".to_sym, Multitenancy.current_tenant
            end
          }
        end

        # @private
        #
        # Define the inherited method
        def define_inherited(association, options)
          define_singleton_method(:inherited) do |child|
            child.tenant association, options
            super(child)
          end
        end

        # @private
        #
        # Set the default scope
        def define_default_scope
          # Set the default_scope to scope to current tenant
          default_scope lambda {
            if Multitenancy.current_tenant
              tenant_id = Multitenancy.current_tenant.id
              if tenant_options[:optional]
                where(tenant_field.to_sym.in => [tenant_id, nil])
              else
                where(tenant_field => tenant_id)
              end
            else
              where(nil)
            end
          }
        end

        # @private
        #
        # Create the index
        def define_index
          index({ tenant_field => 1 }, background: true)
        end
      end
    end
  end
end
