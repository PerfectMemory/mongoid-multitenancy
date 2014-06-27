require "mongoid"
require "mongoid/multitenancy/document"
require "mongoid/multitenancy/version"
require "mongoid/validators/tenant_validator"
require "bson/object_id"

module Mongoid
  module Multitenancy
    class << self

      # Returns true if using Mongoid 4
      def mongoid4?
        Mongoid::VERSION.start_with? '4'
      end

      # Set the current tenant. Make it Thread aware
      # This sets a single tenant for primary (creation)
      # as well as scoping (search/delete) purposes
      def current_tenant=(tenant)
        self.set_tenants tenant
      end

      # Returns the current tenant
      def current_tenant
        Thread.current[:current_tenant]
      end

      # set primary and secondary tentants in a Thread aware container
      # Primary tenant is the the one used for creation and validations
      # The combined list of Secondary tenants + Primary tenant is used
      # for the scoping purposes (search/delete)
      def set_tenants(primary_tenant, *secondary_tenants)
        Thread.current[:current_tenant] = primary_tenant
        scoping_tenants = []
        secondary_tenants.map do |t|
          if BSON::ObjectId.legal?(t)
            scoping_tenants << t
          else
            scoping_tenants << t.id
          end
        end

        if primary_tenant && !scoping_tenants.include?(primary_tenant.id)
          Thread.current[:scoping_tenants] = (scoping_tenants << primary_tenant.id)
        elsif !scoping_tenants.empty?
          Thread.current[:scoping_tenants] = scoping_tenants
        else
          Thread.current[:scoping_tenants] = nil
        end
      end

      # Returns the array of tenant-ids to be used for scoping
      def scoping_tenants
        Thread.current[:scoping_tenants]
      end

      # Affects a tenant temporary for a block execution
      def with_tenant(tenant, &block)
        if block.nil?
          raise ArgumentError, "block required"
        end

        old_primary = self.current_tenant
        old_secondary = self.scoping_tenants
        self.set_tenants tenant

        block.call

        self.set_tenants old_primary, *old_secondary
      end
    end
  end
end
