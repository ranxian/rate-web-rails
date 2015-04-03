require 'zip'

class Algorithm
  include Mongoid::Document
  include Mongoid::Timestamps
  include ReaderWriter
  
  field :name, type: String
  field :description, type: String, default: 'No description'
  field :uuid, type: String
  belongs_to :author, class_name: 'User', inverse_of: 'algorithms'
  has_many :tasks

  has_and_belongs_to_many :readers, class_name: 'User', inverse_of: 'reading_algorithms'
  has_and_belongs_to_many :writers, class_name: 'User', inverse_of: 'writing_algorithms'

  def short_uuid
    self.uuid ? self.uuid.split('-')[0] : self.uuid
  end

  def short_uuid
    self.uuid ? self.uuid.split('-')[0] : self.uuid
  end

  def self.generate!(user, options)
    # Prepare algorithm zip
    enroll_exe = options[:enroll_exe]
    match_exe = options[:match_exe]
    random_dir_name = "alg-#{SecureRandom.hex}"
    zip_filepath = Rails.root.join('tmp', random_dir_name + '.zip')
    # TODO: create zip file
    Zip::File.open(zip_filepath, Zip::File::CREATE) do |zipfile|
      zipfile.add('enroll.exe', enroll_exe.tempfile.path)
      zipfile.add('match.exe', match_exe.tempfile.path)
    end
    options[:path] = zip_filepath.to_s

    client = RateClient.new
    client.create('algorithm', options)
    client.wait
    ratealg = client.result
    client.destroy
    alg = Algorithm.new(name: options[:name],
                        description: options[:description],
                        uuid: ratealg['uuid'])
    alg.author = user
    alg.save!
    return alg
  end

  def enroll_exe_url
    RateClient.static_file_url ['algorithms', self.uuid, 'enroll.exe']
  end

  def match_exe_url
    RateClient.static_file_url ['algorithms', self.uuid, 'match.exe']
  end

  after_create do
    self.writers.push self.author
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
