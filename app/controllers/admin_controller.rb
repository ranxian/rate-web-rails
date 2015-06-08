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

  def worker_heartbeat
    ip = request.remote_ip
    machine = Machine.find_or_create_by(ip: ip)
    machine.update_attributes params.permit(:cpupercent, :memtotal, :memavailable, :mempercent)
    machine.last_heartbeat = DateTime.now
    machine.save!

    render json: { result: 'success' }
  end

  def machines
    @machines = Machine.all.asc(:ip)
  end

end
