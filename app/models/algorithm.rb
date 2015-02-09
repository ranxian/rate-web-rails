class Algorithm
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :description, type: String
  field :uuid, type: String

  belongs_to :author, class_name: 'User'
  has_many :tasks

  def short_uuid
    self.uuid.split('-')[0]
  end

  def self.generate!(user, options)
    client = RateClient.new
    client.create('algorithm', options)
    client.wait
    ratealg = client.result
    client.destroy
    alg = Algorithm.new(name: options[:name],
                        description: options[:description],
                        uuid: ratealg['uuid'])
    alg.save!
    return alg
  end

  before_destroy do
    client = RateClient.new
    result = client.delete('algorithm', self.uuid)
    if not result.success?
      logger.debug(result)
    end
    client.destroy
  end
end
