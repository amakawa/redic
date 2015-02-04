require_relative "redic/client"

class Redic
  attr :url
  attr :client

  def initialize(url = "redis://127.0.0.1:6379", timeout = 10_000_000)
    @url = url
    @client = Redic::Client.new(url, timeout)
  end

  def buffer
    Thread.current[:redic_buffer] ||= []
  end

  def configure(url, timeout = 10_000_000)
    @url = url
    @client.configure(url, timeout)
  end

  def call(*args)
    @client.connect do
      @client.write(args)
      @client.read
    end
  end

  def queue(*args)
    buffer << args
  end

  def commit
    @client.connect do
      buffer.each do |args|
        @client.write(args)
      end

      buffer.map do
        @client.read
      end
    end
  ensure
    buffer.clear
  end

  def timeout
    @client.timeout
  end
end
