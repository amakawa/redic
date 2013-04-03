require "redis"

class Redic
  def initialize(options = {})
    @client = Redis::Client.new(options)
    @buffer = []
  end

  def call(*args)
    @client.send(:ensure_connected) do
      @client.write(args)
      @client.read
    end
  end

  def write(*args)
    @buffer << args
  end

  def run
    @client.send(:ensure_connected) do
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
