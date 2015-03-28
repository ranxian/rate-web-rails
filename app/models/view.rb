class View
  include Mongoid::Document
  include Mongoid::Timestamps
  # 名字
  field :name, type: String
  # 描述
  field :description, type: String, default: 'No description'
  # 类数
  field :num_of_classes, type: Integer
  # 样本数
  field :num_of_samples, type: Integer
  # 在 RATE-server 数据库中的 id
  field :uuid, type: String
  # 策略
  field :strategy, type: Symbol
  VALID_STRATEGIES = [:all, :file, :import_tag]
  # 策略相关字段
  field :import_tag, type: String
  # 后台任务 ID
  field :job_id, type: String
  field :done, type: Boolean, default: false
  # 生成用户
  belongs_to :generator, class_name: 'User', inverse_of: 'generated_views'
  # 在 View 上建立的 benchmark
  has_many :benches

  def short_uuid
    self.uuid ? self.uuid.split('-')[0] : self.uuid
  end

  ##
  # 依据 options 的内容创建一个 view.
  # 
  # === Parameters
  # 
  # [user (User)] user who creates the view
  # [options (Hash)] options to create a view, see @create_view in rate_client.rb
  #
  # === Return
  #
  # [View] a view created
  #
  def self.generate!(user, options)
    view = View.new(name: options[:name], strategy: options[:strategy], import_tag: options[:import_tag])
    view.generator = user
    view.job_id = GenerateViewWorker.perform_async(view.id.to_s, options)
    view.save

    return view
  end

  def progress
    (Sidekiq::Status::get_all self.job_id)["at"].to_f
  end

  before_destroy do
    # Cancel job
    if not self.done
      Sidekiq::Status.cancel self.job_id
    end
    self.benches.each do |b|
      b.destroy
    end
    client = RateClient.new
    result = client.delete('view', self.uuid)
    if not result.success?
      logger.debug(result.to_s)
    end
    client.destroy
  end
end
