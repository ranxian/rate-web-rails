require 'zip'

class Algorithm
  include Mongoid::Document
  include Mongoid::Timestamps
  include ReaderWriter
  
  field :name, type: String
  field :description, type: String, default: 'No description'
  field :uuid, type: String
  field :checked, type: Boolean, default: false
  field :usable, type: Boolean, default: false
  field :match_speed, type: Float
  field :enroll_speed, type: Float

  belongs_to :author, class_name: 'User', inverse_of: 'algorithms'
  has_many :tasks, inverse_of: 'algorithms'
  has_one :checking_task, class_name: 'Task', inverse_of: 'checked_algorithm'

  has_and_belongs_to_many :readers, class_name: 'User', inverse_of: 'reading_algorithms'
  has_and_belongs_to_many :writers, class_name: 'User', inverse_of: 'writing_algorithms'

  def short_uuid
    self.uuid ? self.uuid.split('-')[0] : self.uuid
  end

  def try_check
    if self.checking_task
      task = self.checking_task
      task.update_from_server!
      if task.finished
        self.update_attributes(checked: true)
        self.update_attributes(match_speed: task.ave_match_time, enroll_speed: task.ave_enroll_time)
      end
      if task.fte == 0 && task.ftm == 0 && task.ave_enroll_time <= 1000 && task.ave_match_time <= 500
        self.update_attributes(usable: true)
      else
        self.update_attributes(usable: false)
      end
    end
  end

  # Check correctness of task
  def check
    if self.checked
      return
    end
    benchmark = Bench.where(uuid: 'benchmark-to-check-algorithm').first
    if benchmark == nil
      self.checked = true
      return
    else
      task = Task.run!(self.author, benchmark, self)
      task.secret = true
      task.save
      self.checking_task = task
      self.save!
    end
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
    alg.save
    alg.check
    return alg
  end

  def enroll_exe_url
    RateClient.static_file_url ['algorithms', self.uuid, 'enroll.exe']
  end

  def match_exe_url
    RateClient.static_file_url ['algorithms', self.uuid, 'match.exe']
  end

  before_destroy do
    self.tasks.each do |t|
      t.destroy
    end
    if self.checking_task
      self.checking_task.destroy
    end
    client = RateClient.new
    result = client.delete('algorithm', self.uuid)
    if not result.success?
      logger.debug(result)
    end
    client.destroy
  end
end
