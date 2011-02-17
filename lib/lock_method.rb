# See the README.rdoc for more info!
module LockMethod
  autoload :Config, 'lock_method/config'
  autoload :LockCollection, 'lock_method/lock_collection'

  class Locked < ::StandardError
  end

  def self.config #:nodoc:
    Config.instance
  end
  
  def self.lock_collection #:nodoc:
    LockCollection.instance
  end
    
  # All Objects, including instances and Classes, get the <tt>#clear_lock</tt> method.
  module InstanceMethods
    # Clear the lock for a particular method.
    #
    # Example:
    #     my_blog.clear_lock :get_latest_entries
    def clear_lock(method_id)
      ::LockMethod.lock_collection.clear self, method_id
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
        ::LockMethod.lock_collection.attempt self, method_id, ttl, *args do
          send original_method_id, *args
        end
      end
    end
  end
end

unless ::Object.method_defined? :lock_method
  ::Object.send :include, ::LockMethod::InstanceMethods
  ::Object.extend ::LockMethod::ClassMethods
end
