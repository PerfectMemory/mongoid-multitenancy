class IndexableWithoutIndex
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :tenant, class_name: 'Account'
end

class IndexableWithIndexTrue
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :tenant, class_name: 'Account', index: true
end

class IndexableWithIndexFalse
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :tenant, class_name: 'Account', index: false
end

class IndexableWithoutFullIndexes
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  field :title, type: String
  field :name, type: String
  field :slug, type: String

  tenant :tenant, class_name: 'Account'

  index(title: 1)
  index({ name: 1 }, { full_index: true })
  index({ slug: 1 }, { full_index: false })
end

class IndexableWithFullIndexesFalse
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  field :title, type: String
  field :name, type: String

  tenant :tenant, class_name: 'Account', full_indexes: false

  index(title: 1)
  index({ name: 1 }, { full_index: true })
end

class IndexableWithFullIndexesTrue
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  field :title, type: String
  field :name, type: String

  tenant :tenant, class_name: 'Account', full_indexes: true

  index(title: 1)
  index({ name: 1 }, { full_index: false })
end
