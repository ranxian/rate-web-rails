class GenerateBenchmarkWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(bench_id, options)
    total 1
    options = options.symbolize_keys

    # Create RATE benchmark
    client = RateClient.new
    client.create('benchmark', options)

    while client.running
      at client.progress, ""
      sleep 0.5
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