class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  # task 名
  field :name, type: String
  # 得分
  field :score, type: Float
  # uuid
  field :uuid, type: String
  # 是否已经完成
  field :finished, type: DateTime
  # task 进度
  field :progress, type: Float, default: 0.0
  
  belongs_to :runner, class_name: 'User', inverse_of: 'tasks'
  belongs_to :algorithm
  belongs_to :bench

  def short_uuid
    self.uuid ? self.uuid.split('-')[0] : self.uuid
  end

  def update_from_server
    client = RateClient.new
    ratetask = client.info('task', self.uuid)
    client.destroy
    self.finished = ratetask['finished'] if ratetask['finished']
    self.score = ratetask['score']
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
    self.score = nil
    self.save
    client = RateClient.new
    client.run(self.algorithm.uuid, self.bench.uuid)
    client.destroy
  end

  def self.run!(user, bench, algorithm, options = {})
    client = RateClient.new
    client.run(algorithm.uuid, bench.uuid)
    ratetask = client.result
    client.destroy
    
    if ratetask.success?
      task = Task.new(name: options[:name],
                      score: ratetask['score'],
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

  def roc_grapg_url
    RateClient.static_file_url(['tasks', self.uuid, 'roc.png'])
  end

  def fmr_fnmr_graph_url
    RateClient.static_file_url ['tasks', self.uuid, 'fmrFnmr.png']
  end

  def score_graph_url
    RateClient.static_file_url ['tasks', self.uuid, 'score.png']
  end

  def result_file_url
    RateClient.static_file_url ['tasks', self.uuid, 'match_result_bxx.txt']
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

  before_destroy do
    client = RateClient.new
    result = client.delete('task', self.uuid)
    if not result.success?
      logger.debug(result)
    end
    client.destroy
  end
end
