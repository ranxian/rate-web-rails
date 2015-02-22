class Algorithm
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :description, type: String
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
    dir = Rails.root.join('tmp', random_dir_name)
    FileUtils.mkdir(dir)
    `cp #{enroll_exe.tempfile.path} #{dir.join('enroll.exe')}`
    FileUtils.cp(enroll_exe.tempfile.path, dir.join('enroll.exe'))
    FileUtils.cp(enroll_exe.tempfile.path, dir.join('match.exe'))
    zip_filepath = Rails.root.join('tmp', random_dir_name + '.zip')
    # TODO: create zip file
    options[:path] = zip_filepath

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
