module XAPI
  class Cache
    @client = false # Shared Dalli ElasticCache client for instance

    # durations are measured in minutes
    DEFAULT = 60

    class << self
      def get(key)
        cache.get key
      rescue Dalli::DalliError, SocketError
        nil
      end

      def set(key, value, expires_in=DEFAULT)
        cache.set key, value, expires_in.minutes.to_i
      rescue Dalli::DalliError, SocketError
        nil
      end
      alias_method(:add, :set)

      def delete(key)
        cache.delete key
      rescue Dalli::DalliError, SocketError
        nil
      end

      def invalidate(key)
        cache.delete key
      rescue Dalli::DalliError, SocketError
        nil
      end

      def valid?(key)
        cache.get(key) ? true : false
      rescue Dalli::DalliError, SocketError
        nil
      end

      # no block given - read from cache;
      # block given: if the key has expired, execute the block and write to cache
      #              if the key is present, read and return the current key value 
      # ttl is not supported
      def fetch(key, expires_in=DEFAULT)
        if block_given?
          entry = get key
          entry ||= cache_block_value(key, expires_in) { |_key| yield _key }
        else
          get key
        end
      end

      def cache
        unless @client
          endpoint = ApiService.settings.memcached_servers
          options = {
            expires_in: DEFAULT.minutes.to_i,
            namespace: "XAPI::#{ApiService.settings.environment.to_s.upcase}"
          }
          @client = Dalli::ElastiCache.new(endpoint,options).client
        end
        @client
      end

      def cache_block_value(key, expires_in)
        value = yield key
        add key, value, expires_in
        value
      end
    end

    private_class_method :cache_block_value
  end
end