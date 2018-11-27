require_relative "redic/client"

class Redic
  attr :url
  attr :client

  def initialize(url = "redis://127.0.0.1:6379", timeout = 10_000_000)
    @url = url
    @client = Redic::Client.new(url, timeout)
    @buffer = Hash.new { |h, k| h[k] = [] }
  end

  def buffer
    @buffer[Thread.current.object_id]
  end

  def reset
    @buffer.delete(Thread.current.object_id)
  end

  def clear
    @buffer.clear
  end

  def configure(url, timeout = 10_000_000)
    if @url != url
      @url = url
      @client.configure(url, timeout)
    end
  end

  def call(*args)
    @client.connect do
      @client.write(args)
      @client.read
    end
  end

  def call!(*args)
    reply = call(*args)

    if RuntimeError === reply
      raise reply
    end

    return reply
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
    reset
  end

  def timeout
    @client.timeout
  end

  def timeout=(timeout)
    @client.timeout = timeout
  end

  def quit
    @client.quit
  end
end
