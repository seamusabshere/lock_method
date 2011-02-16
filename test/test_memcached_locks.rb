require 'helper'

class TestMemcachedLocks < Test::Unit::TestCase
  def setup
    LockMethod.config.client = $my_cache
    LockMethod.locks.flush
  end
    
  include SharedTests
end
