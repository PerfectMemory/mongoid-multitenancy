class Indexable
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :client, class_name: 'Account', index: true
end
