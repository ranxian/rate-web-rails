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
  def self.generate!(user, options)
    # Create a RATE view
    client = RateClient.new
    client.create('view', options)
    client.wait
    rateview = client.result
    client.destroy
    # Store view in RATE-web
    view = View.new(name: options[:name], 
                    description: options[:name],
                    strategy: options[:strategy],
                    uuid: rateview['uuid'],
                    num_of_samples: rateview['sample_count'],
                    num_of_classes: rateview['class_count'])
    view.generator = user
    view.save!
    return view
  end

  before_destroy do
    client = RateClient.new
    result = client.delete('view', self.uuid)
    if not result.success?
      logger.debug(result.to_s)
    end
    client.destroy
  end
end
