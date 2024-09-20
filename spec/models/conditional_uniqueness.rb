class ConditionalUniqueness
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant(:tenant, class_name: 'Account', optional: true)

  field :slug, type: String
  field :approved, type: Boolean, default: false

  validates_tenant_uniqueness_of :slug, conditions: -> { where(approved: true) }
  validates_presence_of :slug

  index(title: 1)
end
