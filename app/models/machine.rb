class Machine
  include Mongoid::Document

  field :last_heartbeat, type: DateTime
  field :ip, type: String
  field :cpupercent, type: Float
  field :memtotal, type: Float
  field :memavailable, type: Float
  field :mempercent, type: Float

  def self.remove_offline
    Machine.where(:last_heartbeat.lte => 10.minute.ago).delete_all
  end

  def self.notify_task
    Machine.each do |m|
      url = "http://#{m.ip}:8080/update_task?uuids=" + Manager.instance.task_list.join(',')
      begin
        Curl.get(url)
      rescue
      end
    end
  end

  def shutdown
    url = "http://#{self.ip}:8080/shutdown"
    begin
      Curl.get(url)
    rescue
    end
  end

  def start
    url = "http://#{self.ip}:8080/restart"
    begin
      Curl.get(url)
    rescue
    end
  end

  def pull_worker(worker_path)
    url = "http://#{self.ip}:8080/pull_worker?worker_path=#{worker_path}"
    begin
      Curl.get(url)
    rescue
    end
  end
end
