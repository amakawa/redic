require "redic/client"

class Redic
  attr :url
  attr :client

  def initialize(url = "redis://127.0.0.1:6379")
    @url = url
    @client = Redic::Client.new(url)
    @queue = []
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
      @queue.each do |args|
        @client.write(args)
      end

      @queue.map do
        @client.read
      end
    end
  ensure
    @queue.clear
  end
end
