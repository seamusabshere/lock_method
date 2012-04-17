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

  MUTEX = ::Mutex.new

  def LockMethod.config #:nodoc:
    @config || MUTEX.synchronize do
      @config ||= Config.new
    end
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
      options = args.extract_options!
      options = options.symbolize_keys
      method_id = args.first
      if args.last.is_a?(::Numeric)
        options[:ttl] ||= args.last
      end
      original_method_id = "_unlocked_#{method_id}"
      alias_method original_method_id, method_id
      define_method method_id do |*args1|
        options = options.merge(:args => args1)
        lock = ::LockMethod::Lock.new self, method_id, options
        lock.call_and_lock(*([original_method_id]+args1))
      end
    end
  end
end

::Object.send :include, ::LockMethod::InstanceMethods
::Class.send :include, ::LockMethod::ClassMethods
::Module.send :include, ::LockMethod::ClassMethods
