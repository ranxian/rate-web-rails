class GenerateViewWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(view_id, options)
    total 1
    options = options.symbolize_keys
    client = RateClient.new
    client.create('view', options)

    while client.running
      at client.progress, ""
      sleep 0.5
    end

    rateview = client.result
    client.destroy
    # Store view in RATE-web
    if rateview.success?
      view = View.find(view_id)
      view.uuid = rateview['uuid']
      view.num_of_samples = rateview['sample_count']
      view.num_of_classes = rateview['class_count']
      view.done = true
      view.save!
    else
      raise rateview.message
    end
  end
end