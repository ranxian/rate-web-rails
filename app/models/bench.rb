class Bench
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :description, type: String
  field :num_of_genuine, type: Integer
  field :num_of_imposter, type: Integer
  field :strategy, type: Symbol
  VALID_STRATEGIES = [:general]
  field :uuid, type: String

  belongs_to :generator, class_name: 'User', inverse_of: 'generated_benchs'
  belongs_to :view
  has_many :tasks

  def self.generate(user, strategy, options)
    
  end
end
