module Varnish
  class Client
    # Default management port of varnishd
    DEFAULT_PORT = 6082

    # We assume varnishd on localhost
    DEFAULT_HOST = 'localhost'

    DEFAULT_OPTS = {
      :keep_alive => false,
      :timeout    => 1
    }

    # timeout in seconds when connecting to varnishd. Default is 1
    attr_accessor :timeout

    # set to true, to keep the connection alive. Default is false
    attr_accessor :keep_alive

    # hostname or IP-address of varnishd. Default is "localhost"
    attr_accessor :host

    # port number of varnishd. Default is 6082
    attr_accessor :port

    # Examples:
    # 
    #   Client.new "127.0.0.1"
    #   Client.new "mydomain.com:6082"
    #   Client.new :timeout => 5
    #   Client.new "10.0.0.3:6060", :timeout => nil, :keep_alive => true
    #
    # === Configuration options
    #
    # +timeout+:: if specified (seconds), calls to varnish
    #             will be wrapped in a timeout, default is 1 second.
    #             Disable with <tt>:timeout => nil</tt>
    # +keep_alive+:: if true, the connection is kept alive by sending
    #                ping commands to varnishd every few seconds
    def initialize(*args)
      opts = {}

      case args.length
      when 0
        self.server = DEFAULT_HOST
      when 1
        arg = args[0]
        case arg
        when String
          self.server = arg
        when Hash
          self.server = DEFAULT_HOST
          opts = arg
        end
      when 2
        self.server = args[0]
        opts = args[1]
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
      end

      opts = DEFAULT_OPTS.merge(opts)
      @timeout     = opts[:timeout]
      @keep_alive  = opts[:keep_alive]

      @mutex = Mutex.new
    end

    # Set the varnishd management host and port.
    # Expects a string as "hostname" or "hostname:port"
    def server=(server)
      @host, @port = server.split(':')
      @port = (@port || DEFAULT_PORT).to_i
      server
    end

    # Returns the varnishd management host and port as "hostname:port"
    def server
      "#{@host}:#{@port}"
    end

    # Manipulate the VCL configuration
    # 
    #  .vcl :load, <configname>, <filename>
    #  .vcl :inline, <configname>, <quoted_VCLstring>
    #  .vcl :use, <configname>
    #  .vcl :discard, <configname>
    #  .vcl :list
    #  .vcl :show, <configname>
    #
    # Ex.:
    #   v = Varnish.new
    #   v.vcl :load, "newconf", "/etc/varnish/myconf.vcl"
    def vcl(op, *params)
      cmd("vcl.#{op}", *params)
    end

    # Purge objects from the cache or show the purge queue.
    #
    #  .purge :url, <regexp>
    #  .purge :hash, <regexp>
    #  .purge :list
    #  .purge <costum-field> <args>
    #
    # +op+:: :url, :hash, :list or a custom field
    # +regexp+:: a string containing a varnish compatible regexp
    #
    # Ex.:
    #   v = Varnish.new
    #   v.purge :url, '.*'
    def purge(op, *regexp_or_args)
      c = [:url, :hash, :list].include?(op) ? "purge.#{op}" : "purge #{op}"
      cmd(c, *regexp_or_args)
    end

    # Ping the server to keep the connection alive
    def ping(timestamp = nil)
      cmd("ping", timestamp)
    end

    # Returns a hash of status information
    def stats
      result = cmd("stats")
      Hash[*result.split("\n").map { |line|
          stat = line.strip!.split(/\s+/, 2)
          [stat[1], stat[0].to_i]
        }.flatten
      ]
    end

    # Set and show parameters
    #
    #  .param :show, [-l], [<param>]
    #  .param :set, <param>, <value>
    def param(op, *args)
      cmd("param.#{op}", *args)
    end

    # Returns the status string from varnish.
    # See also #running? and #stopped?
    def status
      cmd("status")
    end

    def start
      bool cmd("start")
    end

    def stop
      bool cmd("stop")
    end

    def running?
      bool status =~ /running/
    end

    def stopped?
      bool status =~ /stopped/
    end

    # close the connection to varnishd.
    # Note that the connection will automatically be re-established
    # when another command is issued.
    def disconnect
      if connected?
        @conn.write "quit\n"
        @conn.gets
        @conn.close unless @conn.closed?
      end
    end
    
    def connected?
      bool @conn && !@conn.closed?
    end

    private

    # Sends a command to varnishd.
    # Raises an Varnish::Error when a non-200 status is returned
    # Returns the response text
    def cmd(name, *params)
      @mutex.synchronize do
        connect unless connected?
        @conn.write "#{name} #{params.join(' ')}\n"
        status, length = @conn.gets.split # <status> <content_length>\n
        content = @conn.read(length.to_i + 1) # +1 = \n
        content.chomp!
        raise Error, "Command #{name} returned with status #{status}: #{content}" if status.to_i != 200
        content
      end
    end

    def connect
      @conn = SocketFactory.tcp_socket(@host, @port, @timeout)

      # If keep alive, we ping the server every few seconds.
      if @keep_alive
        varnish = self
        Thread.new do
          while(true) do
            if varnish.connected?
              varnish.ping
              sleep 5
            else
              break
            end
          end
        end
      end

      @conn
    end

    # converts +value+ into a boolean
    def bool(value)
      !!value
    end
    
  end
end
