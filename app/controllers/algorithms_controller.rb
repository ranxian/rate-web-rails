class AlgorithmsController < ApplicationController
  before_action :set_algorithm, only: [:show, :edit, :update, :destroy, :add_reader, :add_writer,
                                  :remove_writer, :remove_reader]

  # GET /algorithms
  # GET /algorithms.json
  def index
    @algorithms = Algorithm.all.desc(:created_at)
  end

  # GET /algorithms/1
  # GET /algorithms/1.json
  def show
  end

  # GET /algorithms/new
  def new
    @algorithm = Algorithm.new
  end

  # GET /algorithms/1/edit
  def edit
  end

  # POST /algorithms
  # POST /algorithms.json
  def create
    @algorithm = Algorithm.generate!(current_user, algorithm_params)

    respond_to do |format|
      if @algorithm.save
        format.html { redirect_to @algorithm, notice: 'Algorithm was successfully created.' }
        format.json { render :show, status: :created, location: @algorithm }
      else
        format.html { render :new }
        format.json { render json: @algorithm.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /algorithms/1
  # PATCH/PUT /algorithms/1.json
  def update
    respond_to do |format|
      if @algorithm.update(algorithm_params)
        format.html { redirect_to @algorithm, notice: 'Algorithm was successfully updated.' }
        format.json { render :show, status: :ok, location: @algorithm }
      else
        format.html { render :edit }
        format.json { render json: @algorithm.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /algorithms/1
  # DELETE /algorithms/1.json
  def destroy
    @algorithm.destroy
    respond_to do |format|
      format.html { redirect_to algorithms_url, notice: 'Algorithm was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def remove_reader
    user = User.find(params[:user_id])
    @algorithm.readers.delete user
    redirect_to :back
  end

  def remove_writer
    user = User.find(params[:user_id])
    @algorithm.writers.delete user
    redirect_to :back
  end

  def add_reader
    user = Usre.find_by(email: params[:email])
    if not @algorithm.readable?(user)
      @algorithm.readers.push user
    end
    redirect_to :back
  end

  def add_writer
    user = User.find_by(email: params[:email])
    @algorithm.readers.delete(user)
    @algorithm.writers.push(user)
    redirect_to :back
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_algorithm
      @algorithm = Algorithm.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def algorithm_params
      params.require(:algorithm).permit(:name, :description, :enroll_exe, :match_exe)
    end
end
