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

      if @uri.scheme == "redis"
        @uri.password && assert_ok(call("AUTH", @uri.password))
        @uri.path != "" && assert_ok(call("SELECT", @uri.path[1..-1]))
      end
    end

    def call(*args)
      @semaphore.synchronize do
        write(args)
        read
      end
    end

    def connected?
      @connection && @connection.connected?
    end

    def assert(value, error)
      raise error unless value
    end

    def assert_ok(reply)
      assert(reply == "OK", reply)
    end
  end
end
