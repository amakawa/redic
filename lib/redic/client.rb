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
      @semaphore = Mutex.new
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

    def connect
      tries = 0

      begin
        establish_connection unless connected?

        tries += 1

        @semaphore.synchronize do
          yield
        end

      rescue ConnectionError => err
        disconnect

        if tries < 3
          retry
        else
          raise err
        end

      rescue Exception => err
        disconnect
        raise err
      end
    end

  private
    def establish_connection
      @connection = Connection::Ruby.connect(@uri)

      authenticate
      selectdb

    rescue TimeoutError
      raise CannotConnectError,
            "Timed out connecting to Redis on #{location}"
    rescue Errno::ECONNREFUSED
      raise CannotConnectError,
            "Error connecting to Redis on #{location} (ECONNREFUSED)"
    end

    def authenticate
      if uri.password
        @semaphore.synchronize do
          write [:auth, uri.password] 
          read
        end
      end
    end

    def selectdb
      if uri.path && uri.path != "/0"
        @semaphore.synchronize do
          write [:select, uri.path[1..-1]] 
          read
        end
      end
    end

    def connected?
      @connection && @connection.connected?
    end

    def disconnect
      @connection.disconnect if connected?
    end

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
  end
end
