class View
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :description, type: String
  field :num_of_classes, type: Integer
  field :num_of_samples, type: Integer

  belongs_to :generator, class_name: 'User', inverse_of: 'generated_views'
  has_many :benchs

  def self.generate!(user, strategy, options)
    
  end
end
