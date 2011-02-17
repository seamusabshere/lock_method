require 'helper'

require 'memcached'

class TestMemcachedStorage < Test::Unit::TestCase
  def setup
    LockMethod.config.storage = Memcached.new 'localhost:11211'
    LockMethod.storage.flush
  end
    
  include SharedTests
end
