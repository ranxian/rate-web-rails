class AdminController < ApplicationController

  skip_before_filter :authenticate_user!

  def task_list
    render json: { task_uuids: Manager.instance.task_list }
  end

  def add_task
    uuid = params[:uuid]
    Manager.add_task(uuid)
    render json: { result: 'success' }
  end

  def remove_task
    uuid = params[:uuid]
    Manager.remove_task(uuid)
    render json: { result: 'success' }
  end

end
