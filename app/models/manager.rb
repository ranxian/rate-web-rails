class Manager
  include Mongoid::Document

  field :task_list, type: Array, default: []
  field :last_update_task_at, type: DateTime

  def self.instance
    if Manager.count == 0
      Manager.create
    end

    Manager.first
  end

  def self.add_task(uuid)
    manager = Manager.instance
    manager.task_list.push uuid
    manager.last_update_task_at = Time.now
    manager.save
  end

  def self.remove_task(uuid)
    manager = Manager.instance
    manager.task_list.delete uuid
    manager.last_update_task_at = Time.now
    manager.save
  end
end
