require "hiredis/connection"

class Redic
  module Connection
    TIMEOUT = 10_000_000

    def self.new(uri)
      connection = Hiredis::Connection.new

      if uri.scheme == "unix"
        connection.connect_unix(uri.path, TIMEOUT)
      else
        connection.connect(uri.host, uri.port, TIMEOUT)
      end

      connection
    end
  end
end
