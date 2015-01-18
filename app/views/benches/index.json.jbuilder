json.array!(@benches) do |bench|
  json.extract! bench, :id, :name, :description, :num_of_genuine, :num_of_imposter, :strategy
  json.url bench_url(bench, format: :json)
end
