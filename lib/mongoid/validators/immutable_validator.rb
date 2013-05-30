class ImmutableValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    if object.send(:attribute_changed?, options[:field])  and object.send(:attribute_was, options[:field])
      object.errors.add(options[:field], 'is immutable and cannot be updated') and false
    end
  end
end