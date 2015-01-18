class View
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :description, type: String
  field :num_of_classes, type: Integer
  field :num_of_samples, type: Integer
  field :uuid, type: String
  field :strategy, type: Symbol
  VALID_STRATEGIES = [:file, :import_tag, :all]

  belongs_to :generator, class_name: 'User', inverse_of: 'generated_views'
  has_many :benchs

  # Generate views according to strategies
  # For :file, a file path is provided, this file should reside in RATE_ROOT/temp
  # For :import_tag, a import_tag is provided.
  def self.generate!(user, options)
    rateview = nil
    client = RateClient.new
    rateview = client.create_view(options)
    client.destroy


  end
end
