require "redic/client"

class Redic
  attr :url
  attr :client

  def initialize(url = "redis://127.0.0.1:6379")
    @url = url
    @client = Redic::Client.new(url)
    @queue = Queue.new
  end

  def call(*args)
    @client.connect do
      @client.write(args)
      @client.read
    end
  end

  def queue(*args)
    @queue << args
  end

  def commit
    @client.connect do
      size = 0
      repl = []

      until @queue.empty?
        @client.write(@queue.pop)
        size += 1
      end

      size.times do
        repl << @client.read
      end

      repl
    end
  ensure
    @queue.clear
  end
end
