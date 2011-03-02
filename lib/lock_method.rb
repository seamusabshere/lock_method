require 'lock_method/version'
# See the README.rdoc for more info!
module LockMethod
  autoload :Config, 'lock_method/config'
  autoload :Lock, 'lock_method/lock'
  autoload :DefaultStorageClient, 'lock_method/default_storage_client'

  # This is what gets raised when you try to run a locked method.
  class Locked < ::StandardError
  end

  def self.config #:nodoc:
    Config.instance
  end
  
  # All Objects, including instances and Classes, get the <tt>#clear_method_lock</tt> method.
  module InstanceMethods
    # Clear the lock for a particular method.
    #
    # Example:
    #     my_blog.clear_method_lock :get_latest_entries
    def clear_method_lock(method_id)
      lock = ::LockMethod::Lock.new :obj => self, :method_id => method_id
      lock.delete
    end
  end

  # All Classes (but not instances), get the <tt>.lock_method</tt> method.
  module ClassMethods
    # Lock a method. TTL in seconds, defaults to whatever's in LockMethod.config.default_ttl
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
    def lock_method(method_id, ttl = nil)
      original_method_id = "_unlocked_#{method_id}"
      alias_method original_method_id, method_id
      define_method method_id do |*args|
        lock = ::LockMethod::Lock.new :obj => self, :method_id => method_id, :original_method_id => original_method_id, :args => args, :ttl => ttl
        lock.call_original_method
      end
    end
  end
end

unless ::Object.method_defined? :lock_method
  ::Object.send :include, ::LockMethod::InstanceMethods
  ::Class.send :include, ::LockMethod::ClassMethods
end
