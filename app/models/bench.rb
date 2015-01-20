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

  def self.generate!(user, options)
    # Create RATE benchmark
    client = RateClient.new
    client.create('benchmark', options)
    client.wait
    ratebench = client.result
    client.destroy
    # Store RATE-web benchmark
    bench = Bench.new(name: options[:name],
                      description: options[:description],
                      strategy: options[:strategy],
                      num_of_genuine: ratebench[:genuine_count],
                      num_of_imposter: ratebench[:imposter_count],
                      uuid: ratebench[:uuid]
                      )
    bench.generator = user
    bench.save!
    return bench
  end
end
