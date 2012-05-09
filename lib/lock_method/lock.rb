require 'digest/sha1'

module LockMethod
  class Lock #:nodoc: all
    attr_reader :obj
    attr_reader :method_id
    attr_reader :args
    attr_reader :blk
    attr_reader :original_method_id
    attr_reader :method_signature
    attr_reader :ttl
    attr_reader :args_digest

    def initialize(obj, method_id, args = nil, ttl = LockMethod.config.default_ttl, spin = false, &blk)
      @mutex = ::Mutex.new
      @obj = obj
      @method_id = method_id
      @original_method_id = LockMethod.original_method_id method_id
      @method_signature = LockMethod.method_signature obj, method_id
      @args = args
      @args_digest = args.to_a.empty? ? 'empty' : LockMethod.digest(args)
      @ttl = ttl #!!!!!
      @spin = spin
      @blk = blk
    end
    
    def delete
      LockMethod.config.storage.delete cache_key
    end
    
    def save
      LockMethod.config.storage.set cache_key, self, ttl
    end
    
    def locked?
      !!LockMethod.config.storage.get(cache_key)
    end
    
    def marshal_dump
      []
    end
    
    def marshal_load(source)
      # nothing
    end
    
    def call_and_lock
      while locked? and spin?
        ::Kernel.sleep 0.5
      end
      if locked?
        raise Locked, %{#{method_signature} is currently locked.}
      else
        begin
          save
          obj.send(*([original_method_id]+args), &blk)
        ensure
          delete
        end
      end
    end

    private

    def cache_key
      if obj.is_a?(::Class) or obj.is_a?(::Module)
        [ 'LockMethod', 'Lock', method_signature, args_digest ].join ','
      else
        [ 'LockMethod', 'Lock', method_signature, LockMethod.digest(obj), args_digest ].join ','
      end
    end

    def spin?
      @spin == true
    end
  end
end