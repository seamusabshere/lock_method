require 'singleton'
module LockMethod
  # All storage requests go through a clearinghouse.
  class Storage #:nodoc: all
    autoload :DefaultStorageClient, 'lock_method/storage/default_storage_client'
    
    include ::Singleton
    
    def delete(k)
      if defined?(::Memcached) and bare_storage.is_a?(::Memcached)
        begin; bare_storage.delete(k); rescue ::Memcached::NotFound; nil; end
      elsif defined?(::Redis) and bare_storage.is_a?(::Redis)
        bare_storage.del k
      else
        bare_storage.delete k
      end
    end
    
    def flush
      bare_storage.send %w{ flush flush_all clear flushdb }.detect { |c| bare_storage.respond_to? c }
    end
    
    def get(k)
      if defined?(::Memcached) and bare_storage.is_a?(::Memcached)
        begin; bare_storage.get(k); rescue ::Memcached::NotFound; nil; end
      elsif defined?(::Redis) and bare_storage.is_a?(::Redis)
        if cached_v = bare_storage.get(k) and cached_v.is_a?(::String)
          ::Marshal.load cached_v
        end
      elsif bare_storage.respond_to?(:get)
        bare_storage.get k
      elsif bare_storage.respond_to?(:read)
        bare_storage.read k
      else
        raise "Don't know how to work with #{bare_storage.inspect}"
      end
    end
        
    def set(k, v, ttl)
      ttl ||= ::LockMethod.config.default_ttl
      if defined?(::Redis) and bare_storage.is_a?(::Redis)
        if ttl == 0
          bare_storage.set k, ::Marshal.dump(v)
        else
          bare_storage.setex k, ttl, ::Marshal.dump(v)
        end
      elsif bare_storage.respond_to?(:set)
        bare_storage.set k, v, ttl
      elsif bare_storage.respond_to?(:write)
        if ttl == 0
          bare_storage.write k, v # never expire
        else
          bare_storage.write k, v, :expires_in => ttl
        end
      else
        raise "Don't know how to work with #{bare_storage.inspect}"
      end
    end
    
    def bare_storage
      Config.instance.storage
    end
  end
end
