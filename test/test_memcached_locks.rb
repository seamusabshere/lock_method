require 'helper'

class TestMemcachedLockCollection < Test::Unit::TestCase
  def setup
    LockMethod.config.storage = $my_cache
    LockMethod.lock_collection.flush
  end
    
  include SharedTests
end
