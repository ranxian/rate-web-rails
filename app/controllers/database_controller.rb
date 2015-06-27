class DatabaseController < ApplicationController
  before_filter :authenticate_vip!

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
    if params[:sample_uuids_file].present?
      @tempfile = params[:sample_uuids_file].tempfile
      @lines = File.readlines @tempfile
      @uuids = @lines.map(&:chomp).reject { |line| line == '' }
      
      @samples = RateClient.get_samples_by_uuids(@uuids)
    elsif params[:class_uuids_file].present?
      @tempfile = params[:class_uuids_file].tempfile
      class_uuids = (File.readlines @tempfile).map(&:chomp).reject { |line| line == '' }
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

  def browse_by_query
    per_page = 100
    @query_command = params[:query_command]
    checked_command = @query_command.clone
    @page = 1
    if params[:page].present?
      @page = params[:page].to_i
    end

    ['insert', 'update', 'delete'].each do |command|
      if @query_command.include?(command) || @query_command.include?(command.upcase)
        redirect_to :back, notice: 'ILLEGAL SQL'
        return
      end
    end

    if not @query_command.upcase.include?('LIMIT')
      checked_command << " LIMIT #{(@page-1) * per_page},#{per_page}"
    end

    @samples = RateClient.get_samples_by_query(checked_command).reject { |s| s == nil }

    @by_class = params[:by_class]
    if @by_class == 'yes'
      class_samples = {}
      @samples.each do |sample|
        class_samples[sample[:class_uuid]] ||= []
        class_samples[sample[:class_uuid]] << sample
      end
      @samples = class_samples.map do |k, v|
        ["# CLASS #{k}", v]
      end.flatten
    end
  end
end
