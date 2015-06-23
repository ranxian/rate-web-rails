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
      client.destroy
      redirect_to :back, notice: 'Parameters not correct'
    end

    if params[:view_name].present?
      view_options = {name: params[:view_name], strategy: 'import_tag', import_tag: import_tag}
      View.generate!(current_user, view_options)
    end

    client.destroy

    redirect_to database_path
  end

  def browse
    if params[:sample_uuids_file]
      @tempfile = params[:sample_uuids_file].tempfile
      @lines = File.readlines @tempfile
      @uuids = @lines.map { |uuid| uuid.chomp }
      
      @samples = RateClient.get_samples_by_uuids(@uuids)
    elsif params[:class_uuids_file]
      @tempfile = params[:class_uuids_file].tempfile
      class_uuids = (File.readlines @tempfile).map(&:chomp)
      class_samples = RateClient.get_samples_by_class(class_uuids)

      @samples = class_samples.flat_map do |k, v|
        if k.starts_with?('#')
          k
        else
          ["# CLASS #{k}", v]
        end
      end.flatten
    end
  end
end
