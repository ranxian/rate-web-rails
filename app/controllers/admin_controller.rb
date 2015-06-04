class AdminController < ApplicationController

  def task_list
    render json: { task_uuids: Manager.instance.task_list }
  end

  def add_task
    uuid = params[:uuid]
    Manager.add_task(uuid)
  end

  def remove_task
    uuid = params[:uuid]
    Manager.remove_task(uuid)
  end

end
