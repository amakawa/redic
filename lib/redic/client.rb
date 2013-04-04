require "redic/errors"
require "redic/connection"
require "socket"
require "cgi"

class Redic
  class Client

    DEFAULTS = {
      :url => lambda { ENV["REDIS_URL"] },
      :scheme => "redis",
      :host => "127.0.0.1",
      :port => 6379,
      :path => nil,
      :timeout => 5.0,
      :password => nil,
      :db => 0,
      :id => nil,
      :tcp_keepalive => 0
    }

    def scheme
      @options[:scheme]
    end

    def host
      @options[:host]
    end

    def port
      @options[:port]
    end

    def path
      @options[:path]
    end

    def timeout
      @options[:timeout]
    end

    def password
      @options[:password]
    end

    def db
      @options[:db]
    end

    def db=(db)
      @options[:db] = db.to_i
    end

    attr_reader :connection
    attr_reader :command_map

    def initialize(options = {})
      @options = _parse_options(options)
      @reconnect = true
      @connection = nil
      @command_map = {}
    end

    def connect
      @pid = Process.pid

      establish_connection
      call [:auth, password] if password
      call [:select, db] if db != 0
      self
    end

    def id
      @options[:id] || "redis://#{location}/#{db}"
    end

    def location
      path || "#{host}:#{port}"
    end

    def connected?
      connection && connection.connected?
    end

    def disconnect
      connection.disconnect if connected?
    end

    def reconnect
      disconnect
      connect
    end

    def io
      yield
    rescue TimeoutError
      raise TimeoutError, "Connection timed out"
    rescue Errno::ECONNRESET, Errno::EPIPE, Errno::ECONNABORTED, Errno::EBADF, Errno::EINVAL => e
      raise ConnectionError, "Connection lost (%s)" % [e.class.name.split("::").last]
    end

    def read
      io do
        connection.read
      end
    end

    def write(command)
      io do
        connection.write(command)
      end
    end

  protected

    def establish_connection
      @connection = Connection::Ruby.connect(@options.dup)

    rescue TimeoutError
      raise CannotConnectError, "Timed out connecting to Redis on #{location}"
    rescue Errno::ECONNREFUSED
      raise CannotConnectError, "Error connecting to Redis on #{location} (ECONNREFUSED)"
    end

    def ensure_connected
      tries = 0

      begin
        if connected?
          if Process.pid != @pid
            raise InheritedError,
              "Tried to use a connection from a child process without reconnecting. " +
              "You need to reconnect to Redis after forking."
          end
        else
          connect
        end

        tries += 1

        yield
      rescue ConnectionError
        disconnect

        if tries < 2 && @reconnect
          retry
        else
          raise
        end
      rescue Exception
        disconnect
        raise
      end
    end

    def _parse_options(options)
      defaults = DEFAULTS.dup
      options = options.dup

      defaults.keys.each do |key|
        # Fill in defaults if needed
        if defaults[key].respond_to?(:call)
          defaults[key] = defaults[key].call
        end

        # Symbolize only keys that are needed
        options[key] = options[key.to_s] if options.has_key?(key.to_s)
      end

      url = options[:url] || defaults[:url]

      # Override defaults from URL if given
      if url
        require "uri"

        uri = URI(url)

        if uri.scheme == "unix"
          defaults[:path]   = uri.path
        else
          # Require the URL to have at least a host
          raise ArgumentError, "invalid url" unless uri.host

          defaults[:scheme]   = uri.scheme
          defaults[:host]     = uri.host
          defaults[:port]     = uri.port if uri.port
          defaults[:password] = CGI.unescape(uri.password) if uri.password
          defaults[:db]       = uri.path[1..-1].to_i if uri.path
        end
      end

      # Use default when option is not specified or nil
      defaults.keys.each do |key|
        options[key] ||= defaults[key]
      end

      if options[:path]
        options[:scheme] = "unix"
        options.delete(:host)
        options.delete(:port)
      else
        options[:host] = options[:host].to_s
        options[:port] = options[:port].to_i
      end

      options[:timeout] = options[:timeout].to_f
      options[:db] = options[:db].to_i

      case options[:tcp_keepalive]
      when Hash
        [:time, :intvl, :probes].each do |key|
          unless options[:tcp_keepalive][key].is_a?(Fixnum)
            raise "Expected the #{key.inspect} key in :tcp_keepalive to be a Fixnum"
          end
        end

      when Fixnum
        if options[:tcp_keepalive] >= 60
          options[:tcp_keepalive] = {:time => options[:tcp_keepalive] - 20, :intvl => 10, :probes => 2}

        elsif options[:tcp_keepalive] >= 30
          options[:tcp_keepalive] = {:time => options[:tcp_keepalive] - 10, :intvl => 5, :probes => 2}

        elsif options[:tcp_keepalive] >= 5
          options[:tcp_keepalive] = {:time => options[:tcp_keepalive] - 2, :intvl => 2, :probes => 1}
        end
      end

      options
    end
  end
end
