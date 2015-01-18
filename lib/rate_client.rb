# encoding: utf-8
require 'socket'
require 'json'
require 'pp'

class RateResult
  attr_reader :json

  def initialize(init_object)
    if init_object.is_a?(Hash)
      @json = init_object
    elsif init_object.is_a?(String)
      @json = JSON.parse(init_object)
    end
  end

  def method_missing(method, *args)
    if @json.respond_to?(method)
      return @json.send(method, *args)
    else
      if method.to_s.end_with?('=')
        @json[method.to_s[0..-2]] = args.first
      end
      return @json[method.to_s]
    end
  end

  def to_s
    @json.to_s
  end

  def success?
    self.result == 'success'
  end

  def extract(*fieldnames)
    results = @json['contents'].map do |j|
      result = []
      fieldnames.each do |fieldname|
        result << j[fieldname]
      end
      result
    end
    results
  end

  def first
    RateResult.new @json['contents'].first
  end
end

class RateClient
  attr_accessor :host, :port, :verbose, :progress
  
  def initialize(options = {})
    @config = YAML.load_file(Rails.root.join('config', 'rate.yml'))

    @host = @config['rate_host']
    @port = @config['rate_port']
    @socket = TCPSocket.new(host, port)
    @verbose = false
    @progress = 0.0
  end

  def need_arg!(options, arg)
    raise ":#{arg.to_s} needed" if not options[arg]
  end

  def issue(command)
    @socket.puts command

    receive
  end

  def receive
    msg = ""
    progress = -1
    
    loop do
      line = @socket.gets.chomp
      break if line == "BEGIN"
    end

    loop do
      line = @socket.gets.chomp
      
      if line == "PROGRESS"
        @progress = 0
        next
      elsif line == "DONE"
        @progress = 1
        next
      elsif line == "END"
        break
      else
        if @progress >= 0 && @progress < 1
          @progress = line.to_f
        else
          msg << line
        end
      end
    end

    RateResult.new(msg)
  end

  def create_view(options = {})
    need_arg! options, :strategy
    need_arg! options, :path if options[:strategy] == 'file'
    need_arg! options, :import_tag if options[:strategy] == 'import_tag'
    if options[:strategy] == 'file' &&  !File.exists?(options[:path])
      return RateResult.new({ 'result' => 'failed', 'message' => "No such file: #{options[:path]}" })
    end

    cmd = ['create']
    cmd << 'view'
    cmd << "strategy:#{options[:strategy]}"

    if options[:strategy] == 'file'
      @socket.puts cmd.join(' ')
      send_file options[:path]
    elsif options[:strategy] == 'import_tag'
      cmd << "import_tag:#{options[:import_tag]}"
      @socket.puts cmd.join(' ')
    else
      @socket.puts cmd.join(' ')
    end
    result = self.receive
  end

  def create_benchmark(options = {})
    need_arg! options, :strategy
    need_arg! options, :view
    if options[:strategy] == 'general' || options[:strategy] == 'allN'
      need_arg! options, :class_count
      need_arg! options, :sample_count 
    end
    need_arg! options, :path if options[:strategy] == 'file'
    file_exist! options[:path] if options[:strategy] == 'file'

    cmd = ['create']
    cmd << 'benchmark'
    cmd << "strategy:#{options[:strategy]}"
    cmd << "view_uuid:#{options[:view]['uuid']}"
    if options[:strategy] == 'general' || options[:strategy] == 'allN'
      cmd << "class_count:#{options[:class_count]}" << "sample_count:#{options[:sample_count]}"
      @socket.puts cmd.join(' ')
    elsif options[:strategy] == 'file'
      @socket.puts cmd.join(' ')
      send_file options[:path]
    else
      @socket.puts cmd.join(' ')
    end
      
    result = receive
  end

  def create(options = {})
    need_arg! options, :target
    if options[:target] == 'algorithm'
      result = create_algorithm(options)
    elsif options[:target] == 'benchmark'
      result = create_benchmark(options)
    elsif options[:target] == 'view'
      result = create_view(options)
    else
    end

    if @verbose
      if result.success?
        puts "#{options[:target]} #{options[:name]} created"
      else
        puts "#{options[:target]} can't be created"
        puts result[:message]
      end
    end

    result
  end

  def delete(options = {})
    need_arg! options, :target
    need_arg! options, :uuid
    result = self.issue "delete #{options[:target]} uuid:#{options[:uuid]}"
    if result.success? && @verbose
      puts "#{options[:target]} deleted"
    end
    result
  end


  def create_algorithm(options = {})
    file_exist! options[:path]

    if not options[:path].end_with?(".zip")
      return RateResult.new({ 'result' => 'failed', 
        'message' => "Algorithm must be compressed into zip" })
    end

    cmd = ['create']
    cmd << 'algorithm'

    @socket.puts cmd.join(' ')
    send_file(options[:path])

    receive
  end

  def download(options = {})
    need_arg! options, :target
    need_arg! options, :uuid
    need_arg! options, :path
    
    if options[:target] != 'image'
      r = self.info(options)
      return r if not r.success?
    end

    path = options[:path]
    @socket.puts "download #{options[:target]} uuid:#{options[:uuid]}"
    result = receive
    if result.success?
      if File.directory?(path)
        path = File.join(path, 
          options[:target] + '-' + options[:uuid].split('-')[0] + '.zip')
      end
      file = File.new(path, "wb")
      receive_file(file)
      file.close
      result.file = file.path
    end

    result
  end

  def update(options = {})
    need_arg! options, :target
    need_arg! options, :uuid
    target = options[:target]
    uuid = options[:uuid]
    options.delete(:target)
    options.delete(:uuid)
    update_items = options.map do |k, v|
      [k.to_s + ':' + v.to_s]
    end.join(' ')

    puts "update #{target} uuid:#{uuid} #{update_items}"

    self.issue("update #{target} uuid:#{uuid} #{update_items}")
  end

  def run(options = {})
    need_arg! options, :auuid
    need_arg! options, :buuid
    cmd = "run auuid:#{options[:auuid]} buuid:#{options[:buuid]}"
    self.issue cmd
  end

  def kill(options = {})
    need_arg! options, :uuid
    cmd = "kill uuid:#{options[:uuid]}"
    self.issue cmd
  end

  def info(options = {})
    need_arg! options, :target
    need_arg! options, :uuid
    cmd = "info #{options[:target]} uuid:#{options[:uuid]}"
    self.issue cmd
  end

  def list(options = {})
    need_arg! options, :target
    cmd = "list #{options[:target]}"

    self.issue cmd
  end

  def destroy
    @socket.close
  end

  private 

  def send_file(path)
    file = File.new(path, 'r')
    @socket.puts file.size

    @socket.write file.read(file.size)
    @socket.flush
    file.close
  end

  def receive_file(file)
    length = @socket.gets.to_i
    have_read = 0
    rdsize = 1024 * 128 # 128K

    b = Time.now
    while have_read < length
      to_read = [rdsize, length - have_read].min
      file.write @socket.read(to_read)  
      have_read += to_read

      el = Time.now - b
      speed = have_read / Float(el)
      print_pbar(Float(have_read)/length, "[%.2f/%.2f(M)] %.2f KB/s" % [have_read/1024.0/1024, length/1024.0/1024, speed/1024.0])
    end

    puts
  end
end
