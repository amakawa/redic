require "redic/client"

class Redic
  attr :url
  attr :client

  def initialize(url = "redis://127.0.0.1:6379")
    @url = url
    @client = Redic::Client.new(url)
    @pipe = []
  end

  def call(*args)
    @client.connect do
      @client.write(args)
      @client.read
    end
  end

  def pipe(*args)
    @pipe << args
  end

  def run
    @client.connect do
      @pipe.each do |args|
        @client.write(args)
      end

      @pipe.map do
        @client.read
      end
    end
  ensure
    @pipe.clear
  end
end
