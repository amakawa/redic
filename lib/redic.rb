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

      err = nil

      result = @buffer.map do
        begin
          @client.read
        rescue RuntimeError => e
          err = e
        end
      end

      if err
        raise err
      else
        return result
      end
    end
  ensure
    @buffer.clear
  end
end
