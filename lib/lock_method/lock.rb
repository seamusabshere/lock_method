require 'digest/md5'
module LockMethod
  class Lock #:nodoc: all
    class << self
      def find(cache_key)
        Config.instance.storage.get cache_key
      end
      def klass_name(obj)
        (obj.is_a?(::Class) or obj.is_a?(::Module)) ? obj.to_s : obj.class.to_s
      end
      def method_delimiter(obj)
        (obj.is_a?(::Class) or obj.is_a?(::Module)) ? '.' : '#'
      end
      def method_signature(obj, method_id)
        [ klass_name(obj), method_id ].join method_delimiter(obj)
      end
    end

    attr_reader :obj
    attr_reader :method_id
    attr_reader :args

    def initialize(obj, method_id, options = {})
      @obj = obj
      @method_id = method_id
      options = options.symbolize_keys
      @ttl = options[:ttl]
      @args = options[:args]
      @spin = options[:spin]
    end
    
    def spin?
      @spin == true
    end
    
    def method_signature
      @method_signature ||= Lock.method_signature(obj, method_id)
    end
    
    def ttl
      @ttl ||= Config.instance.default_ttl
    end
    
    def obj_hash
      @obj_hash ||= obj.respond_to?(:method_lock_hash) ? obj.method_lock_hash : obj.hash
    end

    def args_digest
      @args_digest ||= args.to_a.empty? ? 'empty' : ::Digest::MD5.hexdigest(args.join)
    end
        
    def delete
      Config.instance.storage.delete cache_key
    end
    
    def save
      Config.instance.storage.set cache_key, self, ttl
    end
    
    def locked?
      !!Lock.find(cache_key)
    end
    
    def cache_key
      if obj.is_a?(::Class) or obj.is_a?(::Module)
        [ 'LockMethod', 'Lock', method_signature, args_digest ].join ','
      else
        [ 'LockMethod', 'Lock', method_signature, obj_hash, args_digest ].join ','
      end
    end
            
    def marshal_dump
      []
    end
    
    def marshal_load(source)
      # nothing
    end
    
    def call_and_lock(*original_method_id_and_args)
      until !spin? or !locked?
        ::Kernel.sleep 0.5
      end
      if locked?
        raise Locked
      else
        begin
          save
          obj.send *original_method_id_and_args
        ensure
          delete
        end
      end
    end
  end
end