require_relative "connection"
require "uri"

class Redic
  class Client
    attr :timeout

    def initialize(url, timeout)
      @uri = URI.parse(url)
      @timeout = timeout
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
      establish_connection unless connected?

      @semaphore.synchronize do
        yield
      end
    rescue Errno::ECONNRESET
      @connection = nil
      retry
    end

  private
    def establish_connection
      begin
        @connection = Redic::Connection.new(@uri, @timeout)
      rescue StandardError => err
        raise err, "Can't connect to: %s" % @uri
      end

      authenticate
      select
    end

    def authenticate
      if @uri.password
        @semaphore.synchronize do
          write ["AUTH", @uri.password]
          read
        end
      end
    end

    def select
      if @uri.path
        @semaphore.synchronize do
          write ["SELECT", @uri.path[1..-1]]
          read
        end
      end
    end

    def connected?
      @connection && @connection.connected?
    end
  end
end
