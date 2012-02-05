require 'rubygems'
require 'eventmachine'
require 'set'
require 'fiber'
require 'em-http'

class Downloader

  def initialize www, workers = 10, &block
    @queue = [{:url => www, :type => :head, :other => nil}]
    @visited = {}
    @traversers = {}
    @workers = []
    @worknum = workers
   
    instance_eval &block
  end

  def traverse type, &block
    @traversers[type] = block
  end

  def process_results &processor
    @result_processor = processor
  end

  def claim_result *args
    if @result_processor
      @result_processor.call *args
  end

  def run
    EM.run do
      @worknum.times do
        start_worker
      end
    end
  end

  def get_url url
    f = Fiber.current
    http = EM::HttpRequest.new(url).get
    http.errback {f.resume http}
    http.callback {f.resume http}
    return Fiber.yield
  end

  private

  def start_worker
    Fiber.new do
      puts ':)'
      loop do
        if @queue.empty? then
          @workers << Fiber.current
          Fiber.yield
        else
          node = @queue[0]
          @queue = @queue.drop 1
          visit_node node
          wake_workers
        end
      end
    end.resume
  end

  def visit_node node
    type = node[:type]
    url = node[:url]
    
    puts "visiting #{url}"

    data = get_url url
    new_nodes = @traversers[type].call data, node[:other]
    new_nodes.select! do |nnode|
      @visited[nnode[:type]] ||= Set.new
      retval = if (@visited[nnode[:type]].member?(nnode[:url])) then false else true end
      @visited[nnode[:type]].add(nnode[:url])
      retval
    end
    @queue += new_nodes
  end

  def wake_workers
    while not(@queue.empty? || @workers.empty?) do
      f = @workers[0]
      @workers = @workers.drop 1
      f.resume
    end
  end
  
end

