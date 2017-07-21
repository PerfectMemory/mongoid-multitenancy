class NoScopable
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :tenant, class_name: 'Account', scopes: false

  field :slug, type: String
  field :title, type: String

  index(title: 1)
end
