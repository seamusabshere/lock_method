module LockMethod
  class Lock #:nodoc: all
    class << self
      def find(cache_key)
        if hsh = Config.instance.storage.get(cache_key)
          new hsh
        end
      end
      def klass_name(obj)
        obj.is_a?(::Class) ? obj.to_s : obj.class.to_s
      end
      def method_delimiter(obj)
        obj.is_a?(::Class) ? '.' : '#'
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

    def initialize(options = {})
      options.each do |k, v|
        instance_variable_set "@#{k}", v
      end
    end

    attr_reader :obj
    attr_reader :method_id
    attr_reader :original_method_id
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
    
    def expiry
      @expiry ||= ::Time.now + ttl
    end
    
    def delete
      Config.instance.storage.delete cache_key
    end
    
    def save
      # make sure these are set
      self.pid
      self.thread_object_id
      self.expiry
      # --
      Config.instance.storage.set cache_key, to_hash, ttl
    end
    
    def to_hash
      instance_variables.inject({}) do |memo, ivar_name|
        memo[ivar_name.to_s.sub('@', '')] = instance_variable_get ivar_name
        memo
      end
    end
    
    def locked?
      if existing_lock = Lock.find(cache_key)
        existing_lock.in_force?
      end
    end
    
    def cache_key
      [ 'LockMethod', 'Lock', method_signature ].join ','
    end
    
    def in_force?
      not expired? and process_and_thread_still_exist?
    end
    
    def expired?
      expiry.to_f < ::Time.now.to_f
    end
    
    def process_and_thread_still_exist?
      if pid == ::Process.pid
        Lock.thread_alive? thread_object_id
      else
        Lock.process_alive? pid
      end
    end
    
    def call_original_method
      if locked?
        raise Locked
      else
        begin
          save
          obj.send original_method_id, *args
        ensure
          delete
        end
      end
    end
  end
end