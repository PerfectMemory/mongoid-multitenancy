require "mongoid"
require "mongoid/multitenancy/document"
require "mongoid/multitenancy/version"
require "mongoid/validators/tenant_validator"

module Mongoid
  module Multitenancy
    class << self

      # Returns true if using Mongoid 4
      def mongoid4?
        Mongoid::VERSION.start_with? '4'
      end

      # Set the current tenant. Make it Thread aware
      def current_tenant=(tenant)
        Thread.current[:current_tenant] = tenant
      end

      # Returns the current tenant
      def current_tenant
        Thread.current[:current_tenant]
      end

      # Affects a tenant temporary for a block execution
      def with_tenant(tenant, &block)
        if block.nil?
          raise ArgumentError, "block required"
        end

        old_tenant = self.current_tenant
        self.current_tenant = tenant

        block.call

        self.current_tenant = old_tenant
      end
    end
  end
end
