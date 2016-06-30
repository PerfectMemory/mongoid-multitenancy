require 'models/mutable'

class MutableChild < Mutable
  field :random, type: String
end

class AnotherMutableChild < Mutable
  field :random, type: String
end
