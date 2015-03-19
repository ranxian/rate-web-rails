class Bench
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :description, type: String, default: 'No description'
  field :num_of_genuine, type: Integer
  field :num_of_imposter, type: Integer
  field :strategy, type: Symbol
  VALID_STRATEGIES = [:general, :all, :allN, :file, :allinter, :allinner, :allInnerOneInter]
  field :uuid, type: String

  field :class_count, type: Integer
  field :sample_count, type: Integer

  belongs_to :generator, class_name: 'User', inverse_of: 'generated_benches'
  belongs_to :view
  has_many :tasks

  def verbose_strategy
    return self.strategy.to_s
  end

  def short_uuid
    self.uuid ? self.uuid.split('-')[0] : self.uuid
  end

  ##
  # Create benchmarks on @view by @options.
  # Valid strategies: general, all, allN, file, allinter, allinner, allInnerOneInter
  #
  # === Parameters
  # 
  # [user (User)] user who creates the benchmark
  # [view (View)] view the benchmark is created on
  # [options (Hash)] options to create benchmark, it must contain all information to
  #                  create a benchmark.
  #
  # === Returns
  # 
  # Benchmark created
  #
  # === Examples
  #
  # @options must include all information to create a benchmark
  # 
  # => options for general benchmark
  # options = { strategy: 'general', class_count: 5, sample_count: 2 }
  # => options for allN benchmark
  # options = { strategy: 'allN', class_count: 5, sample_count: 2 }
  # => options for all, allinter, allinner, allInterOneInter benchmark
  # options = { strategy: 'all' (or 'allinter', 'allinner', 'allInterOneInter') }
  # => options for file benchmark
  # options = { strategy: 'file', path: 'path-to-benchmark-file' }
  # The format of the file is 'UUID1 UUID2 G' perline, where UUIDx is the UUID of the matching samples,
  # and G means genuine, while I means imposter
  #
  def self.generate!(user, view, options)
    # 如果使用文件创建 bench
    if options[:strategy] == 'file'
      options[:path] = options[:file].tempfile.path
    end
    options[:view_uuid] = view.uuid
    # Create RATE benchmark
    client = RateClient.new
    client.create('benchmark', options)
    client.wait
    ratebench = client.result
    client.destroy
    # Store RATE-web benchmark
    if ratebench.success?
      bench = Bench.new(name: options[:name],
                        description: options[:description],
                        strategy: options[:strategy],
                        num_of_genuine: ratebench['genuine_count'],
                        num_of_imposter: ratebench['imposter_count'],
                        uuid: ratebench['uuid'],
                        file: options[:file]
                        )
      bench.generator = user
      bench.view = view
      bench.save!
      return bench
    else
      raise ratebench.message
    end
  end

  def benchmark_file_url
    RateClient.static_file_url ['benchmarks', self.uuid, 'benchmark_bxx.txt']
  end

  def uuid_table_file_url
    RateClient.static_file_url ['benchmarks', self.uuid, 'uuid_table.txt']
  end

  before_destroy do
    client = RateClient.new
    result = client.delete('benchmark', self.uuid)
    if not result.success?
      logger.debug(result.to_s)
    end
    client.destroy
  end
end
