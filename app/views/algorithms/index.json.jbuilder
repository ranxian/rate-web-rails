json.array!(@algorithms) do |algorithm|
  json.extract! algorithm, :id, :name, :description
  json.url algorithm_url(algorithm, format: :json)
end
