class TenantValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    if options[:immutable]
      if object.send(:attribute_changed?, attribute) and object.send(:attribute_was, attribute)
        object.errors.add(attribute, 'is immutable and cannot be updated')
      end
    end

    authorized_values = []
    authorized_values << Mongoid::Multitenancy.current_tenant.id if Mongoid::Multitenancy.current_tenant

    if options[:optional]
      authorized_values << nil
    end

    unless authorized_values.include?(value)
      object.errors.add(attribute, 'value not authorized')
    end
  end
end