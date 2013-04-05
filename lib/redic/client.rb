require "redic/connection"
require "uri"

class Redic
  class Client

    def initialize(url)
      @uri = URI.parse(url)
      @connection = nil
      @semaphore = Mutex.new
    end

    def read
      @connection.read
    end

    def write(command)
      @connection.write(command)
    end

    def connect
      retryable(3) do
        establish_connection unless connected?

        @semaphore.synchronize do
          yield
        end
      end
    end

    def retryable(times)
      tries = 0

      begin
        yield
      rescue Exception => err
        if (tries += 1) <= times
          sleep 0.01
          retry
        else
          raise err, "%s (retries=%d)" % [err.message, tries]
        end
      end
    end

  private
    def establish_connection
      @connection = Redic::Connection.new(@uri)

      authenticate

    rescue Exception => err
       raise err, "Can't connect to: %s" % @uri
    end

    def authenticate
      if @uri.password
        @semaphore.synchronize do
          write [:auth, @uri.password]
          read
        end
      end
    end

    def connected?
      @connection && @connection.connected?
    end
  end
end
