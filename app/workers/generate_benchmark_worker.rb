class GenerateBenchmarkWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(bench_id, options)
    total 1

   # 如果使用文件创建 bench
    if options[:strategy] == 'file'
      options[:path] = options[:file].tempfile.path
    end

    # Create RATE benchmark
    client = RateClient.new
    client.create('benchmark', options.symbolize_keys)

    while client.running
      at client.progress, ""
    end

    ratebench = client.result
    client.destroy
    # Store RATE-web benchmark
    if ratebench.success?
      bench = Bench.find(bench_id)
      bench.num_of_genuine = ratebench['genuine_count']
      bench.num_of_imposter = ratebench['imposter_count']
      bench.uuid = ratebench['uuid']
      bench.done = true
      bench.save!
    else
      raise ratebench.message
    end
  end
end