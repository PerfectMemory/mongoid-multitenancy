class Immutable
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant(:tenant, class_name: 'Account', immutable: true)

  field :slug, type: String
  field :title, type: String

  validates_tenant_uniqueness_of :slug
  validates_presence_of :slug
  validates_presence_of :title

  index(title: 1)
end
