json.array!(@tasks) do |task|
  json.extract! task, :id, :name, :score
  json.url task_url(task, format: :json)
end
