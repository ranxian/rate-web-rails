class Manager
  include Mongoid::Document

  field :task_list, type: Array, default: []

  def self.instance
    if Manager.count == 0
      Manager.create
    end

    Manager.first
  end

  def self.add_task(uuid)
    manager = Manager.instance
    manager.task_list.push uuid
    manager.save
  end

  def self.remove_task(uuid)
    manager = Manager.instance
    manager.task_list.delete uuid
    manager.save
  end
end
