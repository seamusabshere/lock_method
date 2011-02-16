require 'helper'

class TestDefaultLocks < Test::Unit::TestCase
  def setup
    LockMethod.config.client = nil
    LockMethod.locks.flush
  end
  
  include SharedTests
end
