require "redic/errors"
require "redic/connection"
require "socket"
require "uri"

class Redic
  class Client

    attr :uri

    def initialize(url)
      @uri = URI.parse(url)
      @connection = nil
    end

    def connect
      @pid = Process.pid

      establish_connection

      if uri.password
        write [:auth, uri.password] 
        read
      end

      if uri.path && uri.path != "/0"
        write [:select, uri.path[1..-1]] 
        read
      end

      self
    end

    def connected?
      @connection && @connection.connected?
    end

    def disconnect
      @connection.disconnect if connected?
    end

    def read
      io do
        @connection.read
      end
    end

    def write(command)
      io do
        @connection.write(command)
      end
    end

  protected
    def io
      yield
    rescue TimeoutError
      raise TimeoutError, "Connection timed out"
    rescue Errno::ECONNRESET,
           Errno::EPIPE,
           Errno::ECONNABORTED,
           Errno::EBADF,
           Errno::EINVAL
           raise ConnectionError,
                 "Connection lost (%s)" %
                 [$!.class.name.split("::").last]
    end

    def establish_connection
      @connection = Connection::Ruby.connect(@uri)

    rescue TimeoutError
      raise CannotConnectError,
            "Timed out connecting to Redis on #{location}"
    rescue Errno::ECONNREFUSED
      raise CannotConnectError,
            "Error connecting to Redis on #{location} (ECONNREFUSED)"
    end

    def ensure_connected
      tries = 0

      begin
        if connected?
          if Process.pid != @pid
            raise InheritedError,
              "Tried to use a connection from a child " +
              "process without reconnecting. You need " +
              "to reconnect to Redis after forking."
          end
        else
          connect
        end

        tries += 1

        yield

      rescue ConnectionError
        disconnect

        if tries < 3
          retry
        else
          raise
        end

      rescue Exception
        disconnect
        raise
      end
    end
  end
end
