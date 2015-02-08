class View
  include Mongoid::Document
  include Mongoid::Timestamps
  # 名字
  field :name, type: String
  # 描述
  field :description, type: String
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
  mount_uploader :file, FileUploader, ignore_integrity_errors: true
  # 生成用户
  belongs_to :generator, class_name: 'User', inverse_of: 'generated_views'
  # 在 View 上建立的 benchmark
  has_many :benches

  def verbose_strategy
    vs = self.strategy.to_s
    if self.strategy == :import_tag
      vs += "(#{self.import_tag})"
    end
    return vs
  end

  def short_uuid
    self.uuid.split('-')[0]
  end

  # Generate views according to strategies
  def self.generate!(user, options)
    # Create a RATE view
    # 如果使用文件创建 view
    if options[:strategy] == 'file'
      options[:path] = options[:file].tempfile.path
    end
    client = RateClient.new
    client.create('view', options)
    client.wait
    rateview = client.result
    client.destroy
    # Store view in RATE-web
    if rateview.success?
      view = View.new(name: options[:name], 
                      description: options[:name],
                      strategy: options[:strategy],
                      import_tag: options[:import_tag],
                      file: options[:file],
                      uuid: rateview['uuid'],
                      num_of_samples: rateview['sample_count'],
                      num_of_classes: rateview['class_count'])
      view.generator = user
      view.save!
      return view
    else
      raise rateview.message
    end
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
