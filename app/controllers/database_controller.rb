class DatabaseController < ApplicationController
  def index
    
  end

  def import
    
  end

  def do_import
    import_tag = params[:import_tag]
    client = RateClient.new
    
    if params[:zip_file].present? && params[:zip_file]
      path = params[:zip_file].tempfile.path
      client.import(import_tag: import_tag, has_file: true, path: path)
    elsif params[:server_path].present?
      client.import(import_tag: import_tag, has_file: false, zip_path: server_path)
    else
      redirect_to :back, notice: 'Parameters not correct'
    end

    if params[:view_name].present?
      view_options = {name: params[:view_name], strategy: 'import_tag', import_tag: import_tag}
      View.generate!(current_user, view_options)
    end

    redirect_to database_path
  end
end
