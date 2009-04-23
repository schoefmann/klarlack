module Varnish
  # Wrapper around Ruby's Socket.
  #
  # Uses Mike Perhams superior (in both reliability and
  # performance) connection technique with proper timeouts:
  # See: http://github.com/mperham/memcache-client
  class SocketFactory

    begin
      # Try to use the SystemTimer gem instead of Ruby's timeout library
      # when running on something that looks like Ruby 1.8.x. See:
      # http://ph7spot.com/articles/system_timer
      # We don't want to bother trying to load SystemTimer on jruby and
      # ruby 1.9+.
      if !defined?(RUBY_ENGINE)
        require 'system_timer'
        Timer = SystemTimer
      else
        require 'timeout'
        Timer = Timeout
      end
    rescue LoadError => e
      $stderr.puts "[klarlack] Could not load SystemTimer gem, falling back to Ruby's slower/unsafe timeout library: #{e.message}"
      require 'timeout'
      Timer = Timeout
    end

    def self.tcp_socket(host, port, timeout = nil)
      addr = Socket.getaddrinfo(host, nil)
      sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

      if timeout
        secs = Integer(timeout)
        usecs = Integer((timeout - secs) * 1_000_000)
        optval = [secs, usecs].pack("l_2")
        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval

        # Socket timeouts don't work for more complex IO operations
        # like gets which lay on top of read. We need to fall back to
        # the standard Timeout mechanism.
        sock.instance_eval <<-EOR
          alias :blocking_gets :gets
          def gets
            Timer.timeout(#{timeout}) do
              self.blocking_gets
            end
          end
        EOR
      end
      sock.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
      sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      sock
    end

  end
end