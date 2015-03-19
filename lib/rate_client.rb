# encoding: utf-8
require 'socket'
require 'json'
require 'pp'
require 'thread'

#
# RateClient is a ruby wrapper to talk with RATE-server. It could be used to
# create|delete benchmarks, views, run tasks, grab task result and progress, etc. When
# using RateClient to create stuff, it will use a thread to execute, and will not
# block. For all commands, a RateResult object will be returned containing results
# of executing a command.
#
class RateClient
  attr_reader :host, :port, :progress, :running, :result
  attr_accessor :verbose

  ##
  # Get the url on the RATE static server, use this to fetch task results
  #
  def self.static_file_url(arg)
    if arg.is_a?(Array)
      arg = arg.join('/')
    end
    config = YAML.load_file(Rails.root.join('config', 'rate.yml'))
    return "http://#{config['static_host']}/#{arg}"
  end

  ##
  # Initialize a client object from the rate.yml config file.
  #
  def initialize(options = {})
    @config = YAML.load_file(Rails.root.join('config', 'rate.yml'))

    @host = @config['rate_host']
    @port = @config['rate_port']
    @socket = TCPSocket.new(host, port)
    @verbose = false
    @progress = -0.1
    @thread = nil
    @result = nil
    @running = false
  end

  ##
  # Helper methods to detect if arg is a key of options, if not a exception will
  # be raised.
  #
  def need_arg!(options, arg)
    raise ":#{arg.to_s} needed" if not options[arg]
  end

  def file_exist!(path)
    raise "no such file: #{path}" if not File.exist?(path)
  end

  ##
  # Wait for current creating jobs to end if have one, otherwise return immediately.
  #
  def wait
    if @running
      @thread.join
    end
  end

  ##
  # Create RATE resourecs.
  #
  # === Parameters
  #
  # [options (Hash)] :target must be in @options to indicate what to create
  #
  # === Returns
  #
  # [RateResult] view, algorithm, and benchmark created.
  # 
  def create(target, options = {})
    @running = true
    thrd = Thread.new {
      if target == 'algorithm'
        result = create_algorithm(options)
      elsif target == 'benchmark'
        result = create_benchmark(options)
      elsif target == 'view'
        result = create_view(options)
      else
      end

      if @verbose
        if result.success?
          puts "#{target} #{options[:name]} created"
        else
          puts "#{target} can't be created"
          puts result[:message]
        end
      end

      @result = result
      @running = false
    }
    @thread = thrd
  end

  ##
  # Delete RATE-server resources.
  #
  def delete(target, uuid)
    result = self.issue "delete #{target} uuid:#{uuid}"
  end

  ##
  # Download a RATE resource to given path. Fail if a resource is not exist. 
  #
  # === Parameters
  #
  # [target String] RATE resource type
  # [target String] RATE resource uuid
  # [target String] path download to
  #
  def download(target, uuid, path)
    if target != 'image'
      r = self.info(target, uuid)
      return r if not r.success?
    end
    
    @socket.puts "download #{target} uuid:#{uuid}"
    result = receive
    if result.success?
      if File.directory?(path)
        path = File.join(path, 
          target + '-' + uuid.split('-')[0] + '.zip')
      end
      file = File.new(path, "wb")
      receive_file(file)
      file.close
      result.file = file.path
    end

    result
  end

  # PRIVATE API
  def update(target, uuid, options = {})
    update_items = options.map do |k, v|
      [k.to_s + ':' + v.to_s]
    end.join(' ')

    self.issue("update #{target} uuid:#{uuid} #{update_items}")
  end

  ##
  # Run a RATE task.
  #
  # === Parameters
  #
  # [auuid (String)] uuid of algorithm to run task
  # [auuid (String)] uuid of benchmark to evaluate an algorithm
  #
  def run(auuid, buuid)
    cmd = "run auuid:#{auuid} buuid:#{buuid}"
    @result = self.issue cmd
  end

  ##
  # Kill a RATE task.
  #
  # === Parameters
  #
  # [task_uuid (String)] uuid of task to be killed
  def kill(task_uuid)
    cmd = "kill uuid:#{task_uuid}"
    self.issue cmd
  end

  ##
  # Query a RATE resouce's information 
  #
  def info(target, uuid)
    cmd = "info #{target} uuid:#{uuid}"
    self.issue cmd
  end

  ##
  # List RATE resource.
  #
  def list(target)
    cmd = "list #{target}"

    self.issue cmd
  end

  ##
  # Close the client.
  #
  def destroy
    @socket.close
  end

  ### PRIVATE METHOD ###

  ##
  # Send a command to RATE-server.
  #
  # === Parameters
  #
  # [command (String)] command to be sent
  #
  # === Returns
  #
  # [RateResult] result of running the command
  #
  def issue(command)
    @socket.puts command

    receive
  end

  ##
  # Receive data from @socket, and wrap them into a RateResult. @progress will be
  # updated if PROGRESS is received.
  #
  # === Returns
  #
  # [RateResult] data sent from server
  #
  def receive
    msg = ""
    
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

  ##
  # Create a view by given strategy.
  #
  # === Parameters
  #
  # [options (Hash)] options used to create a view, it must contains :strategy
  # and other must-have information to create a view
  #
  # === Returns
  #
  # [RateResult] Created view json file
  #
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

  ##
  # Create a benchmark by given strategy.
  #
  def create_benchmark(options = {})
    need_arg! options, :strategy
    need_arg! options, :view_uuid
    if options[:strategy] == 'general' || options[:strategy] == 'allN'
      need_arg! options, :class_count
      need_arg! options, :sample_count 
    end
    need_arg! options, :path if options[:strategy] == 'file'
    file_exist! options[:path] if options[:strategy] == 'file'

    cmd = ['create']
    cmd << 'benchmark'
    cmd << "strategy:#{options[:strategy]}"
    cmd << "view_uuid:#{options[:view_uuid]}"
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

  ##
  # Create an algorithm.
  #
  def create_algorithm(options = {})
    need_arg! options, :path
    file_exist! options[:path]

    if not options[:path].ends_with?(".zip")
      return RateResult.new({ 'result' => 'failed', 
        'message' => "Algorithm must be compressed into zip" })
    end

    cmd = ['create']
    cmd << 'algorithm'

    @socket.puts cmd.join(' ')
    send_file(options[:path])

    receive
  end

  ##
  # Send a file to RATE-server.
  #
  # === Parameters
  #
  # [file (File)] file to sent
  #
  def send_file(path)
    file = File.new(path, 'r')
    @socket.puts file.size

    @socket.write file.read(file.size)
    @socket.flush
    file.close
  end

  ##
  # Receive a file from RATE-server.
  #
  # === Parameters
  #
  # [file (File)] file to store the received bytes
  #
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
    end
  end
end

class RateResult
  attr_reader :json

  def initialize(init_object)
    if init_object.is_a?(Hash)
      @json = init_object
    elsif init_object.is_a?(String)
      @json = JSON.parse(init_object)
    end
    @json.dup.each do |k, v|
      @json[k.to_sym] = v
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
