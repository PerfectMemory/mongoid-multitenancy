module Mongoid
  module Matchers
    module Validations
      class ValidateTenantUniquenessOfMatcher < ValidateUniquenessOfMatcher
        def initialize(field)
          @field = field.to_s
          @type = 'tenant_uniqueness'
          @options = {}
        end
      end

      def validate_tenant_uniqueness_of(field)
        ValidateTenantUniquenessOfMatcher.new(field)
      end
    end
  end
end
