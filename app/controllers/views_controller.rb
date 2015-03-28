class ViewsController < ApplicationController
  before_action :set_view, only: [:show, :edit, :update, :destroy, :download, 
                                  :progress, :stop_generate]

  # GET /views
  # GET /views.json
  def index
    @views = View.all.desc(:created_at).page(params[:page])
  end

  # GET /views/1
  # GET /views/1.json
  def show
  end

  # GET /views/new
  def new
    @view = View.new
  end

  # GET /views/1/edit
  def edit
  end

  # POST /views
  # POST /views.json
  def create
    @view = View.generate!(current_user, view_params)

    respond_to do |format|
      if @view
        format.html { redirect_to @view, notice: 'View was successfully created.' }
        format.json { render :show, status: :created, location: @view }
      else
        format.html { render :new, notice: 'Cannot create view' }
        format.json { render json: @view.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /views/1
  # PATCH/PUT /views/1.json
  def update
    respond_to do |format|
      if @view.update(view_params)
        format.html { redirect_to @view, notice: 'View was successfully updated.' }
        format.json { render :show, status: :ok, location: @view }
      else
        format.html { render :edit }
        format.json { render json: @view.errors, status: :unprocessable_entity }
      end
    end
  end

  def progress
    render json: { progress: @view.progress }
  end

  # DELETE /views/1
  # DELETE /views/1.json
  def destroy
    @view.destroy
    respond_to do |format|
      format.html { redirect_to views_url, notice: 'View was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_view
      @view = View.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def view_params
      params.require(:view).permit(:name, 
                                   :description, 
                                   :num_of_classes, 
                                   :num_of_samples, 
                                   :strategy,
                                   :import_tag,
                                   :file)
    end
end
