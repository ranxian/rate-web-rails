class Algorithm
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :description, type: String

  belongs_to :author, class_name: 'User'
  has_many :tasks
end
