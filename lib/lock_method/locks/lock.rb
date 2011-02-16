module LockMethod
  class Locks
    class Lock
      class << self
        def parse(str)
          new :method_signature => str
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
          
      def to_str
         method_signature
      end
      alias :to_s :to_str
    end
  end
end