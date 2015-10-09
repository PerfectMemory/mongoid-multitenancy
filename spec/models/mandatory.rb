class Mandatory
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant(:client, :class_name => 'Account')

  field :slug, :type => String
  field :title, :type => String

  validates_tenant_uniqueness_of :slug
  validates_presence_of :slug
  validates_presence_of :title

  index({ :title => 1 })
end
