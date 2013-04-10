require "redic/client"

class Redic
  attr :url

  def initialize(url = "redis://127.0.0.1:6379")
    @url = url
    @client = Redic::Client.new(url)
    @buffer = []
  end

  def call(*args)
    @client.connect do
      @client.write(args)
      @client.read
    end
  end

  def write(*args)
    @buffer << args
  end

  def run
    @client.connect do
      @buffer.each do |args|
        @client.write(args)
      end

      @buffer.map do
        @client.read
      end
    end
  ensure
    @buffer.clear
  end
end
