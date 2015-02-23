require 'zip'

class Algorithm
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :description, type: String, default: 'No description'
  field :uuid, type: String

  mount_uploader :enroll_exe, FileUploader, ignore_integrity_errors: true
  mount_uploader :match_exe, FileUploader, ignore_integrity_errors: true

  belongs_to :author, class_name: 'User'
  has_many :tasks

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
                        enroll_exe: options[:enroll_exe],
                        match_exe: options[:match_exe],
                        uuid: ratealg['uuid'])
    alg.author = user
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
