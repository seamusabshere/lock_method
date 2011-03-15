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
      def process_alive?(pid)
        ::Process.kill 0, pid
      rescue ::Errno::ESRCH
        false
      end
      def thread_alive?(thread_object_id)
        if thr = ::Thread.list.detect { |t| t.object_id == thread_object_id }
          thr.status == 'sleep' or thr.status == 'run'
        end
      end
    end

    def initialize(attrs = {})
      attrs.each do |k, v|
        instance_variable_set "@#{k}", v
      end
    end

    attr_reader :obj
    attr_reader :method_id
    attr_reader :args
        
    def method_signature
      @method_signature ||= Lock.method_signature(obj, method_id)
    end
    
    def ttl
      @ttl ||= Config.instance.default_ttl
    end
    
    def pid
      @pid ||= ::Process.pid
    end
    
    def thread_object_id
      @thread_object_id ||= ::Thread.current.object_id
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
      if other_lock = Lock.find(cache_key)
        other_lock.process_and_thread_still_alive?
      end
    end
    
    def cache_key
      if obj.is_a?(::Class) or obj.is_a?(::Module)
        [ 'LockMethod', 'Lock', method_signature, args_digest ].join ','
      else
        [ 'LockMethod', 'Lock', method_signature, obj_hash, args_digest ].join ','
      end
    end
            
    def process_and_thread_still_alive?
      if pid == ::Process.pid
        Lock.thread_alive? thread_object_id
      else
        Lock.process_alive? pid
      end
    end

    def marshal_dump
      [ pid, thread_object_id ]
    end
    
    def marshal_load(source)
      @pid, @thread_object_id = source
    end
    
    def call_and_lock(*original_method_id_and_args)
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