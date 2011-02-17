require 'singleton'
module LockMethod
  # All lock_collection requests go through a clearinghouse.
  class LockCollection #:nodoc: all
    autoload :Lock, 'lock_method/lock_collection/lock'
    autoload :DefaultStorage, 'lock_method/lock_collection/default_storage'
    
    include ::Singleton
    
    def attempt(obj, method_id, ttl, *args)
      l = Lock.new :obj => obj, :method_id => method_id
      if other_thread_signature = get(l.method_signature) and Lock.valid?(other_thread_signature)
        raise Locked
      else
        begin
          set l.method_signature, l.thread_signature, ttl
          yield
        ensure
          delete l.method_signature
        end
      end
    end
    
    def clear(obj, method_id)
      l = Lock.new :obj => obj, :method_id => method_id
      delete l.method_signature
    end

    def delete(k)
      if defined?(::Memcached) and bare_storage.is_a?(::Memcached)
        begin; bare_storage.delete(k); rescue ::Memcached::NotFound; nil; end
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
        if cached_v = bare_storage.get(k)
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
        bare_storage.set k, ::Marshal.dump(v)
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
      ::LockMethod.config.storage
    end
  end
end
