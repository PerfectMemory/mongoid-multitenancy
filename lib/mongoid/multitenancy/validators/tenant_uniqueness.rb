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
        add_tenant_criterion(criteria, klass, document)

        criteria = criteria.merge(options[:conditions].call) if options[:conditions]

        if Mongoid::VERSION.start_with?('4')
          if criteria.with(persistence_options(criteria)).exists?
            add_error(document, attribute, value)
          end
        else
          if criteria.with(criteria.persistence_options).read(mode: :primary).exists?
            add_error(document, attribute, value)
          end
        end
      end

      # Create the validation criteria for a tenant model.
      #
      # @api private
      def add_tenant_criterion(criteria, base, document)
        tenant_value = document.send(base.tenant_field.to_sym)

        if document.class.tenant_options[:optional]
          if tenant_value
            criteria.selector.update(criterion(document, base.tenant_field, {'$in' => [tenant_value, nil].mongoize}))
          end
        else
          criteria.selector.update(criterion(document, base.tenant_field, tenant_value.mongoize))
        end

        criteria
      end
    end
  end
end
