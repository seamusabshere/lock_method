require 'helper'

class TestDefaultLockCollection < Test::Unit::TestCase
  def setup
    LockMethod.config.storage = nil
    LockMethod.lock_collection.flush
  end
  
  include SharedTests
end
