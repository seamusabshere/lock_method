require 'singleton'
module LockMethod
  # All locks requests go through a clearinghouse.
  class Locks #:nodoc: all
    autoload :Lock, 'lock_method/locks/lock'
    
    include ::Singleton
    
    def attempt(obj, method_id, ttl, *args)
      l = Lock.new :obj => obj, :method_id => method_id
      if other_l = get(l.to_s)
        raise Locked
      else
        begin
          set l.to_s, 'hello', ttl
          yield
        ensure
          delete l.to_s
        end
      end
    end
    
    def clear(obj, method_id)
      l = Lock.new :obj => obj, :method_id => method_id
      delete l.to_s
    end

    def delete(k)
      if defined?(::Memcached) and bare_client.is_a?(::Memcached)
        begin; bare_client.delete(k); rescue ::Memcached::NotFound; nil; end
      else
        bare_client.delete k
      end
    end
    
    def flush
      bare_client.send %w{ flush flush_all clear flushdb }.detect { |c| bare_client.respond_to? c }
    end
    
    def get(k)
      if defined?(::Memcached) and bare_client.is_a?(::Memcached)
        begin; bare_client.get(k); rescue ::Memcached::NotFound; nil; end
      elsif defined?(::Redis) and bare_client.is_a?(::Redis)
        if cached_v = bare_client.get(k)
          ::Marshal.load cached_v
        end
      elsif bare_client.respond_to?(:get)
        bare_client.get k
      elsif bare_client.respond_to?(:read)
        bare_client.read k
      else
        raise "Don't know how to work with #{bare_client.inspect}"
      end
    end
        
    def set(k, v, ttl)
      ttl ||= ::LockMethod.config.default_ttl
      if defined?(::Redis) and bare_client.is_a?(::Redis)
        bare_client.set k, ::Marshal.dump(v)
      elsif bare_client.respond_to?(:set)
        bare_client.set k, v, ttl
      elsif bare_client.respond_to?(:write)
        if ttl == 0
          bare_client.write k, v # never expire
        else
          bare_client.write k, v, :expires_in => ttl
        end
      else
        raise "Don't know how to work with #{bare_client.inspect}"
      end
    end
    
    def bare_client
      ::LockMethod.config.client
    end
  end
end
