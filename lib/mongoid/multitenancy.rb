require 'mongoid'
require 'mongoid/multitenancy/document'
require 'mongoid/multitenancy/version'
require 'mongoid/multitenancy/validators/tenancy'
require 'mongoid/multitenancy/validators/tenant_uniqueness'

module Mongoid
  module Multitenancy
    class << self

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
        raise ArgumentError, 'block required' if block.nil?

        old_tenant = self.current_tenant
        self.current_tenant = tenant
        result = block.call
        self.current_tenant = old_tenant
        result
      end
    end
  end
end
