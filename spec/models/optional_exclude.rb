class OptionalExclude
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant(:tenant, class_name: 'Account', optional: true)

  field :slug, type: String
  field :title, type: String

  validates_tenant_uniqueness_of :slug, exclude_shared: true
  validates_presence_of :slug
  validates_presence_of :title

  index(title: 1)
end
