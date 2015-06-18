class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  # 得分
  field :score, type: Float
  # uuid
  field :uuid, type: String
  # 是否已经完成
  field :finished, type: DateTime
  # 开始任务时间
  field :started_at, type: DateTime
  # task 进度
  field :progress, type: Float, default: 0.0
  field :zeroFNMR, type: Float
  field :zeroFMR, type: Float
  field :fmr100, type: Float
  field :fmr1000, type: Float
  field :fte, type: Integer
  field :ftm, type: Integer
  field :ave_enroll_time, type: Float
  field :ave_match_time, type: Float
  field :secret, type: Boolean, default: false
  
  belongs_to :runner, class_name: 'User', inverse_of: 'tasks'
  belongs_to :algorithm, inverse_of: 'tasks'
  belongs_to :bench
  belongs_to :checked_algorithm, class_name: 'Algorithm', inverse_of: 'checking_task'

  def short_uuid
    self.uuid ? self.uuid.split('-')[0] : self.uuid
  end

  def update_from_server
    client = RateClient.new
    ratetask = client.info('task', self.uuid)
    client.destroy
    self.finished = ratetask['finished'] if ratetask['finished']
    if self.finished
      # RATE-server is in GMT+8, so minus 8
      self.score = ratetask['score'] if ratetask['score']
      self.zeroFNMR = ratetask['zeroFNMR'] if ratetask['zeroFNMR']
      self.zeroFMR = ratetask['zeroFMR'] if ratetask['zeroFMR']
      self.fmr100 = ratetask['FMR100'] if ratetask['FMR100']
      self.fmr1000 = ratetask['FMR1000'] if ratetask['FMR1000']
      self.fte = ratetask['FTE'] if ratetask['FTE']
      self.ftm = ratetask['FTM'] if ratetask['FTM']
      self.ave_match_time = ratetask['aveMatchTime'] if ratetask['aveMatchTime']
      self.ave_enroll_time = ratetask['aveEnrollTime'] if ratetask['aveEnrollTime']
    end
    self.progress = ratetask['progress'] if ratetask['progress']
  end

  def update_from_server!
    self.update_from_server
    self.save!
  end

  def kill
    client = RateClient.new
    client.kill(self.uuid)
    client.destroy
  end

  def rerun
    self.progress = 0
    self.finished = nil
    self.started_at = Time.now
    self.score = nil
    self.save!
    client = RateClient.new
    client.rerun(self.uuid)
    client.destroy
  end

  def continue_task
    self.finished = nil
    self.score = nil
    self.save!
    client = RateClient.new
    client.continue_task(self.uuid)
    client.destroy
  end

  def self.run!(user, bench, algorithm, options = {})
    client = RateClient.new
    client.run(algorithm.uuid, bench.uuid)
    ratetask = client.result
    client.destroy
    
    if ratetask.success?
      task = Task.new(score: ratetask['score'],
                      finished: ratetask['finished'],
                      uuid: ratetask['uuid'])
      task.bench = bench
      task.algorithm = algorithm
      task.runner = user
      task.save!
      return task
    else
      raise ratetask.message
    end
  end

  def genuine_result_file_url
    RateClient.static_file_url(['tasks', self.uuid, 'genuine.txt'])
  end

  def imposter_result_file_url
    RateClient.static_file_url(['tasks', self.uuid, 'imposter.txt.rev.txt'])
  end

  def match_failed_file_url
    RateClient.static_file_url(['tasks', self.uuid, 'match_failed.txt'])
  end

  def enroll_failed_file_url
    RateClient.static_file_url(['tasks', self.uuid, 'enroll_failed.txt'])
  end

  def roc_graph_url
    RateClient.static_file_url(['tasks', self.uuid, 'roc.png'])
  end

  def fmr_fnmr_graph_url
    RateClient.static_file_url ['tasks', self.uuid, 'fmrFnmr.png']
  end

  def score_graph_url
    RateClient.static_file_url ['tasks', self.uuid, 'score.png']
  end

  def uuid_table_file_url
    self.bench.uuid_table_file_url
  end

  def enroll_result_file_url
    RateClient.static_file_url ['tasks', self.uuid, 'enroll_result.txt']
  end

  def imposter_viewer_url
    RateClient.viewer_url ['tasks', self.uuid, 'imposter', 0]
  end

  def genuine_viewer_url
    RateClient.viewer_url ['tasks', self.uuid, 'genuine', 0]
  end

  def uuid_dictionary
    dict1 = {}
    dict2 = {}
    Curl.get(self.uuid_table_file_url).body_str.each_line do |line|
      sp = line.split(' ')
      dict1[sp[0]] = sp[2]
      dict2[sp[1]] = sp[2]
    end

    return dict1, dict2
  end

  def enroll_results
    _, uuid_table = self.uuid_dictionary
    results = Curl.get(self.enroll_result_file_url).body_str.each_line.first(50).map do |line|
      sp = line.split(" ")
      [uuid_table[sp[0]], sp[1]]
    end

    return results
  end

  def failed_match_results
    uuid_table, _ = self.uuid_dictionary

    http = Curl.get(self.match_failed_file_url)
    if http.response_code != 200
      return []
    end

    results = http.body_str.each_line.first(10).map do |line|
      sp = line.split(" ")
      [uuid_table[sp[0]], uuid_table[sp[1]], 'FAIL']
    end

    results
  end

  def failed_enroll_results
    _, uuid_table = self.uuid_dictionary

    http = Curl.get(self.enroll_failed_file_url)

    if http.response_code != 200
      return []
    end

    results = http.body_str.each_line.first(5).map do |line|
      sp = line.split(" ")
      [uuid_table[sp[0]], 'FAIL']
    end

    results
  end

  def match_results
    genuine_results = []
    imposter_results = []
    uuid_table, _ = self.uuid_dictionary

    genuine_results = Curl.get(self.genuine_result_file_url).body_str.each_line.first(50).map do |line|
      sp = line.split(" ")
      [uuid_table[sp[0]], uuid_table[sp[1]], sp[5]]
    end

    imposter_results = Curl.get(self.imposter_result_file_url).body_str.each_line.first(50).map do |line|
      sp = line.split(" ")
      [uuid_table[sp[0]], uuid_table[sp[1]], sp[5]]
    end

    return genuine_results, imposter_results
  end

  after_create do
    self.started_at = Time.now
    self.save
  end

  before_destroy do
    begin
      client = RateClient.new
      result = client.delete('task', self.uuid)
      if not result.success?
        logger.debug(result)
      end
      client.destroy
    rescue
    end
    true
  end
end
