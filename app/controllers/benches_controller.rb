class BenchesController < ApplicationController
  before_action :set_bench, only: [:show, :edit, :update, :destroy, :download, :progress, :add_reader, :add_writer,
                                  :remove_writer, :remove_reader, :publish, :unpublish]

  # GET /benches
  # GET /benches.json
  def index
    @benchs = current_user.writing_benches.desc(:created_at) + current_user.reading_benches.desc(:created_at)
    @benches = Kaminari.paginate_array(@benchs).page(params[:page]).per(20)
  end

  def progress
    render json: { progress: @bench.progress }
  end

  # GET /benches/1
  # GET /benches/1.json
  def show
    if !@bench.readable?(current_user)
      flash[:error] = 'You are not reader of this benchmark'
      redirect_to :back and return
    end

    @tasks = @bench.tasks.asc(:order)
  end

  # GET /benches/new
  def new
    @bench = Bench.new
    @view = View.find(params[:view_id])
  end

  # GET /benches/1/edit
  def edit
    @view = @bench.view
  end

  # POST /benches
  # POST /benches.json
  def create
    @bench = Bench.generate!(current_user, View.find(params[:view_id]), bench_params)

    respond_to do |format|
      if @bench
        format.html { redirect_to @bench, notice: 'Benchmark was successfully created.' }
        format.json { render :show, status: :created, location: @bench }
      else
        format.html { render :new, notice: 'Cannot create benchmark' }
        format.json { render json: @bench.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /benches/1
  # PATCH/PUT /benches/1.json
  def update
    respond_to do |format|
      if @bench.update(bench_params.permit!)
        format.html { redirect_to @bench, notice: 'Benchmark was successfully updated.' }
        format.json { render :show, status: :ok, location: @bench }
      else
        format.html { render :edit }
        format.json { render json: @bench.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /benches/1
  # DELETE /benches/1.json
  def destroy
    @bench.destroy
    respond_to do |format|
      format.html { redirect_to benches_url, notice: 'Benchmark was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def remove_reader
    user = User.find(params[:user_id])
    @bench.readers.delete user
    redirect_to :back
  end

  def remove_writer
    user = User.find(params[:user_id])
    @bench.writers.delete user
    redirect_to :back
  end

  def add_reader
    user = Usre.find_by(email: params[:email])
    if not @bench.readable?(user)
      @bench.readers.push user
    end
    redirect_to :back
  end

  def add_writer
    user = User.find_by(email: params[:email])
    @bench.readers.delete(user)
    @bench.writers.push(user)
    redirect_to :back
  end

  def publish
    @bench.update_attributes(ispublic: true)
    redirect_to :back
  end

  def unpublish
    @bench.update_attributes(ispublic: false)
    redirect_to :back
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bench
      @bench = Bench.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bench_params
      params.require(:bench).permit(:name, 
                                    :description, 
                                    :class_count, 
                                    :sample_count, 
                                    :strategy,
                                    :file)
    end
end
