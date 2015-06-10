class AdminController < ApplicationController

  skip_before_filter :authenticate_user!
  before_filter :set_manager

  def index
    
  end

  def upload_worker
    @manager.workerzip = params[:zipfile]
    @manager.last_update_worker_at = Time.now
    @manager.save!
    Machine.each do |m|
      m.pull_worker(@manager.workerzip.url)
    end
    redirect_to :back    
  end

  def shutdown_all_machines
    Machine.each do |m|
      m.shutdown
    end
    redirect_to :back
  end

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
    Machine.remove_offline
    @machines = Machine.all.desc(:last_heartbeat, :ip)
  end

  private

  def set_manager
    @manager = Manager.instance
  end

end
