json.array!(@views) do |view|
  json.extract! view, :id, :name, :description, :num_of_classes, :num_of_samples
  json.url view_url(view, format: :json)
end
