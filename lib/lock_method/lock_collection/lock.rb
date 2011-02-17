module LockMethod
  class LockCollection
    class Lock
      class << self
        def klass_name(obj)
          obj.is_a?(::Class) ? obj.to_s : obj.class.to_s
        end
        def method_delimiter(obj)
          obj.is_a?(::Class) ? '.' : '#'
        end
        def method_signature(obj, method_id)
          [ klass_name(obj), method_id ].join method_delimiter(obj)
        end
        def thread_signature
          [ ::Process.pid, ::Thread.current.object_id ].join ','
        end
        def valid?(thread_signature)
          pid, thread_object_id = thread_signature.split(',').map { |i| i.to_i }
          if pid == ::Process.pid
            thread_alive? thread_object_id
          else
            process_alive? pid
          end
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
          
      def method_signature
        @method_signature ||= Lock.method_signature(obj, method_id)
      end
      
      def thread_signature
        @thread_signature ||= Lock.thread_signature
      end
    end
  end
end