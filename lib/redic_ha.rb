require_relative "redic/client"
require_relative "redic"

class RedicHA
  attr :sentinel_url
  attr :master_name
  attr :client
  attr :timeout
  attr :db
  attr :queue

  def initialize(master_name, sentinel_url = "redis://127.0.0.1:26379", db = 0, timeout = 10_000_000)
    @sentinel_url = sentinel_url
    @master_name = master_name
    @timeout = timeout
    @client = Redic::Client.new(get_master_url, timeout)
    @db = db 
    @queue = []
  end

  def call(*args)
    exec_with_retry do
      @client.connect do
        @client.write(args)
        @client.read
      end
    end
  end

  def queue(*args)
    @queue << args
  end

  def commit
    exec_with_retry do 
      @client.connect do
        @queue.each do |args|
          @client.write(args)
        end

        @queue.map do
          @client.read
        end
      end
    end
    ensure
      @queue.clear
  end

  def timeout
    @client.timeout
  end

  private

    def get_master_url
      sentinel = Redic.new self.sentinel_url
      reply = sentinel.call "SENTINEL", "masters"
      masters = reply.inject({}) do |m, el|
        m[el[1]] = {
          :ip => el[3],
          :port => el[5]
        }
        m
      end
      master = masters[self.master_name]
      return "redis://#{master[:ip]}:#{master[:port]}/#{@db}"
    end

    def exec_with_retry(&block)
      retries = 20
      begin
        block.call
      rescue Errno::ECONNREFUSED
        if retries >= 0
          retries -= 1
          sleep 0.1
          @client = Redic::Client.new(get_master_url, @timeout)
          retry
        end
      end
    end
end