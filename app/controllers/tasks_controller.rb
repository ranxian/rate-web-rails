class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy, :rerun, :update_from_server, :stop]

  # GET /tasks
  # GET /tasks.json
  def index
    Task.where(finished: nil).each do |task|
      task.update_from_server!
    end
    @tasks = Task.all.desc(:created_at).page(params[:page]).per(20)
  end

  def rerun
    @task.rerun
    redirect_to :back
  end

  def stop
    @task.kill
    redirect_to :back
  end

  def update_from_server
    @task.update_from_server!

    render json: { progress: @task.progress.to_f, score: @task.score }
  end

  def download
    
  end

  # GET /tasks/1
  # GET /tasks/1.json
  def show
    respond_to do |format|
      format.html
      format.json
    end
  end

  # GET /tasks/new
  def new
    @task = Task.new
    @algorithms = current_user.writing_algorithms.desc(:created_at) + current_user.reading_algorithms.desc(:created_at)
    Algorithm.published.each do |a|
      @algorithms << a if not @algorithms.include?(a)
    end
    @benchs = current_user.writing_benches.desc(:created_at) + current_user.reading_benches.desc(:created_at)
    Bench.published.each do |b|
      @benchs << b if not @benchs.include?(b)
    end
  end

  # GET /tasks/1/edit
  def edit
  end

  # POST /tasks
  # POST /tasks.json
  def create
    # Check exist
    @task = Task.where(bench_id: params[:task][:bench_id], algorithm_id: params[:task][:algorithm_id]).first
    if @task
      redirect_to task_path(@task)
    else
      bench = Bench.find(params[:task][:bench_id])
      algorithm = Algorithm.find(params[:task][:algorithm_id])
      @task = Task.run!(current_user, bench, algorithm, { name: params[:task][:name] })
      redirect_to @task, notice: 'Task was successfully created.'
    end
  end

  # PATCH/PUT /tasks/1
  # PATCH/PUT /tasks/1.json
  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to @task, notice: 'Task was successfully updated.' }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.json
  def destroy
    @task.destroy
    respond_to do |format|
      format.html { redirect_to tasks_url, notice: 'Task was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = Task.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def task_params
      params.require(:task).permit(:name, 
                                   :score)
    end
end
