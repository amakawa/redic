require_relative "connection"
require "uri"

class Redic
  class Client
    EMPTY = "".freeze
    SLASH = "/".freeze

    attr_accessor :timeout

    def initialize(url, timeout)
      @semaphore = Mutex.new
      @connection = false

      configure(url, timeout)
    end

    def configure(url, timeout)
      disconnect!

      @uri = URI.parse(url)
      @timeout = timeout
    end

    def read
      @connection.read
    end

    def write(command)
      @connection.write(command)
    end

    def connect
      @semaphore.synchronize do
        begin
          establish_connection unless connected?
          yield
        rescue Errno::ECONNRESET
          @connection = false
          retry
        end
      end
    end

    def connected?
      @connection && @connection.connected?
    end

    def disconnect!
      if connected?
        @connection.disconnect
        @connection = false
      end
    end

    def quit
      if connected?
        assert_ok(@semaphore.synchronize { call("QUIT") })
        disconnect!

        true
      else
        false
      end
    end

  private
    def establish_connection
      begin
        @connection = Redic::Connection.new(@uri, @timeout)
      rescue StandardError => err
        raise err, "Can't connect to: %s" % @uri
      end

      if @uri.scheme != "unix"
        if @uri.password
          assert_ok(call("AUTH", @uri.password))
        end

        if @uri.path != EMPTY && @uri.path != SLASH
          assert_ok(call("SELECT", @uri.path[1..-1]))
        end
      end
    end

    def call(*args)
      write(args)
      read
    end

    def assert(value, error)
      raise error unless value
    end

    def assert_ok(reply)
      assert(reply == "OK", reply)
    end
  end
end
