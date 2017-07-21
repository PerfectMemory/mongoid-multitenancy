class Indexable
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  field :title, type: String

  tenant :tenant, class_name: 'Account', index: true, full_indexes: false

  index(title: 1)
end
