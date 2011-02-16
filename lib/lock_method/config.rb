require 'singleton'
module LockMethod
  # Here's where you set config options.
  #
  # Example:
  #     LockMethod.config.client = Memcached.new '127.0.0.1:11211'
  #
  # You'd probably put this in your Rails config/initializers, for example.
  class Config
    include ::Singleton
    
    # Client for keeping lockfiles.
    #
    # Defaults to using the filesystem's temp dir.
    #
    # Supported memcached clients:
    # * memcached[https://github.com/fauna/memcached] (either a Memcached or a Memcached::Rails)
    # * dalli[https://github.com/mperham/dalli] (either a Dalli::Client or an ActiveSupport::Cache::DalliStore)
    # * memcache-client[https://github.com/mperham/memcache-client] (MemCache, the one commonly used by Rails)
    #
    # Supported Redis clients:
    # * redis[https://github.com/ezmobius/redis-rb] (NOTE: AUTOMATIC CACHE EXPIRATION NOT SUPPORTED)
    #
    # Example:
    #     LockMethod.config.client = Memcached.new '127.0.0.1:11211'
    def client=(client)
      @client = client
    end

    def client #:nodoc:
      @client ||= DefaultClient.new
    end
    
    # TTL for method caches. Defaults to 24 hours.
    #
    # Example:
    #     LockMethod.config.default_ttl = 120 # seconds
    def default_ttl=(seconds)
      @default_ttl = seconds
    end
    
    def default_ttl #:nodoc:
      @default_ttl || 86_400
    end
  end
end
