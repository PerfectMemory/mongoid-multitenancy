module Mongoid
  module Multitenancy
    # Validates whether or not a field is unique against the documents in the
    # database.
    #
    # @example Define the tenant uniqueness validator.
    #
    #   class Person
    #     include Mongoid::Document
    #     include Mongoid::Multitenancy::Document
    #     field :title
    #     tenant :client
    #
    #     validates_tenant_uniqueness_of :title
    #   end
    #
    # It is also possible to limit the uniqueness constraint to a set of
    # records matching certain conditions:
    #   class Person
    #     include Mongoid::Document
    #     include Mongoid::Multitenancy::Document
    #     field :title
    #     field :active, type: Boolean
    #     tenant :client
    #
    #     validates_tenant_uniqueness_of :title, conditions: -> {where(active: true)}
    #   end
    class TenantUniquenessValidator < Mongoid::Validatable::UniquenessValidator
      # Validate a tenant root document.
      def validate_root(document, attribute, value)
        klass = document.class

        while klass.superclass.respond_to?(:validators) && klass.superclass.validators.include?(self)
          klass = klass.superclass
        end
        criteria = create_criteria(klass, document, attribute, value)

        # <<Add the tenant Criteria>>
        criteria = with_tenant_criterion(criteria, klass, document)
        # Add additional conditions
        if options[:conditions]
          conditions = klass.unscoped { options[:conditions].call }
          criteria = criteria.merge(conditions)
        end

        if criteria.read(mode: :primary).exists?
          add_error(document, attribute, value)
        end
      end

      # Add the scope criteria for a tenant model criteria.
      #
      # @api private
      def with_tenant_criterion(criteria, base, document)
        item = base.tenant_field.to_sym
        name = document.database_field_name(item)
        tenant_value = document.attributes[name]

        if document.class.tenant_options[:optional] && !options[:exclude_shared]
          if tenant_value
            criteria = criteria.where(:"#{item}".in => [tenant_value, nil])
          end
        else
          criteria = criteria.where(item => tenant_value)
        end

        criteria
      end
    end
  end
end
