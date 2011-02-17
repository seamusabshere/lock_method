require 'singleton'
module LockMethod
  # Here's where you set config options.
  #
  # Example:
  #     LockMethod.config.storage = Memcached.new '127.0.0.1:11211'
  #
  # You'd probably put this in your Rails config/initializers, for example.
  class Config
    include ::Singleton
    
    # Storage for keeping lockfiles.
    #
    # Defaults to using the filesystem's temp dir.
    #
    # Supported memcached clients:
    # * memcached[https://github.com/fauna/memcached] (either a Memcached or a Memcached::Rails)
    # * dalli[https://github.com/mperham/dalli] (either a Dalli::Client or an ActiveSupport::Cache::DalliStore)
    # * memcache-storage[https://github.com/mperham/memcache-storage] (MemCache, the one commonly used by Rails)
    #
    # Supported Redis clients:
    # * redis[https://github.com/ezmobius/redis-rb] (NOTE: AUTOMATIC CACHE EXPIRATION NOT SUPPORTED)
    #
    # Example:
    #     LockMethod.config.storage = Memcached.new '127.0.0.1:11211'
    def storage=(storage)
      @storage = storage
    end

    def storage #:nodoc:
      @storage ||= Storage::DefaultStorageClient.new
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
