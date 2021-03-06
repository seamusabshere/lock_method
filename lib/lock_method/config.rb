require 'cache'

module LockMethod
  # Here's where you set config options.
  #
  # Example:
  #     LockMethod.config.storage = Memcached.new '127.0.0.1:11211'
  #
  # You'd probably put this in your Rails config/initializers, for example.
  class Config
    def initialize
      @mutex = ::Mutex.new
    end

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
    # * redis[https://github.com/ezmobius/redis-rb]
    #
    # Supports anything that works with the cache[https://github.com/seamusabshere/cache] gem.
    #
    # Example:
    #     LockMethod.config.storage = Memcached.new '127.0.0.1:11211'
    def storage=(storage = nil)
      if storage.nil?
        # set this to nil so that the DefaultStorageClient can take over.
        @storage = nil
      else
        @storage = ::Cache.wrap storage
      end
    end

    def storage #:nodoc:
      @storage || @mutex.synchronize do
        @storage ||= DefaultStorageClient.new
      end
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
