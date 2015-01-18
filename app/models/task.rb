class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :score, type: Float
  field :uuid, type: String

  belongs_to :runner, class_name: 'User', inverse_of: 'run_tasks'
  belongs_to :algorithm
  belongs_to :bench

  def self.run!(user, bench, algorithm, options = {})
    
  end
end
