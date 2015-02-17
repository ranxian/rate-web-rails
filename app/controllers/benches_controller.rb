class BenchesController < ApplicationController
  before_action :set_bench, only: [:show, :edit, :update, :destroy]

  # GET /benches
  # GET /benches.json
  def index
    @benches = current_user.generated_benchs
  end

  # GET /benches/1
  # GET /benches/1.json
  def show
  end

  # GET /benches/new
  def new
    @bench = Bench.new
  end

  # GET /benches/1/edit
  def edit
  end

  # POST /benches
  # POST /benches.json
  def create
    @bench = Bench.new(bench_params)

    respond_to do |format|
      if @bench.save
        format.html { redirect_to @bench, notice: 'Bench was successfully created.' }
        format.json { render :show, status: :created, location: @bench }
      else
        format.html { render :new }
        format.json { render json: @bench.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /benches/1
  # PATCH/PUT /benches/1.json
  def update
    respond_to do |format|
      if @bench.update(bench_params)
        format.html { redirect_to @bench, notice: 'Bench was successfully updated.' }
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
      format.html { redirect_to benches_url, notice: 'Bench was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bench
      @bench = Bench.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bench_params
      params.require(:bench).permit(:name, :description, :num_of_genuine, :num_of_imposter, :strategy)
    end
end
