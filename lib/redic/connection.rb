require "hiredis/connection"

class Redic
  module Connection
    def self.new(uri)
      connection = Hiredis::Connection.new

      if uri.scheme == "unix"
        connection.connect_unix(uri.path)
      else
        connection.connect(uri.host, uri.port)
      end

      connection
    end
  end
end
