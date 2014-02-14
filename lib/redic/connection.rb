require "hiredis/connection"

class Redic
  module Connection
    def self.new(uri, timeout)
      connection = Hiredis::Connection.new

      if uri.scheme == "unix"
        connection.connect_unix(uri.path, timeout)
      else
        connection.connect(uri.host, uri.port, timeout)
      end

      connection
    end
  end
end
