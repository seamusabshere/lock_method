require 'thread'

require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR >= 3
  require 'active_support/core_ext'
end

require 'lock_method/config'
require 'lock_method/lock'
require 'lock_method/default_storage_client'

# See the README.rdoc for more info!
module LockMethod
  # This is what gets raised when you try to run a locked method.
  class Locked < ::StandardError
  end

  def LockMethod.config #:nodoc:
    @config || ::Thread.exclusive do
      @config ||= Config.new
    end
  end

  def LockMethod.original_method_id(method_id)
    "_unlocked_#{method_id}"
  end

  def LockMethod.klass_name(obj)
    (obj.is_a?(::Class) or obj.is_a?(::Module)) ? obj.to_s : obj.class.to_s
  end

  def LockMethod.method_delimiter(obj)
    (obj.is_a?(::Class) or obj.is_a?(::Module)) ? '.' : '#'
  end

  def LockMethod.method_signature(obj, method_id)
    [ klass_name(obj), method_id ].join method_delimiter(obj)
  end

  def LockMethod.resolve_lock(obj)
    case obj
    when ::Array
      obj.map do |v|
        resolve_lock v
      end
    when ::Hash
      obj.inject({}) do |memo, (k, v)|
        kk = resolve_lock k
        vv = resolve_lock v
        memo[kk] = vv
        memo
      end
    else
      obj.respond_to?(:as_lock) ? [obj.class.name, obj.as_lock] : obj
    end
  end

  def LockMethod.digest(obj)
    ::Digest::SHA1.hexdigest ::Marshal.dump(resolve_lock(obj))
  end
  
  # All Objects, including instances and Classes, get the <tt>#lock_method_clear</tt> method.
  module InstanceMethods
    # Clear the lock for a particular method.
    #
    # Example:
    #     my_blog.lock_method_clear :get_latest_entries
    def lock_method_clear(method_id)
      lock = ::LockMethod::Lock.new self, method_id
      lock.delete
    end
  end

  # All Classes (but not instances), get the <tt>.lock_method</tt> method.
  module ClassMethods
    # Lock a method.
    #
    # Options:
    # * <tt>:ttl</tt> TTL in seconds, defaults to whatever's in LockMethod.config.default_ttl
    # * <tt>:spin</tt> Whether to wait indefinitely for another lock to expire
    #
    # Note 2: Check out LockMethod.config.default_ttl... the default is 24 hours!
    #
    # Example:
    #     class Blog
    #       # [...]
    #       def get_latest_entries
    #         sleep 5
    #       end
    #       # [...]
    #       lock_method :get_latest_entries
    #       # if you wanted a different ttl...
    #       # lock_method :get_latest_entries, 800 #seconds
    #     end
    def lock_method(*args)
      options = args.extract_options!.symbolize_keys
      spin = options[:spin]
      ttl = options[:ttl]
      method_id = args.first
      if args.last.is_a?(::Numeric)
        ttl ||= args.last
      end
      alias_method LockMethod.original_method_id(method_id), method_id
      define_method method_id do |*my_args, &blk|
        lock = ::LockMethod::Lock.new(self, method_id, my_args, ttl, spin, &blk)
        lock.call_and_lock
      end
    end
  end
end

::Object.send :include, ::LockMethod::InstanceMethods
::Class.send :include, ::LockMethod::ClassMethods
::Module.send :include, ::LockMethod::ClassMethods
