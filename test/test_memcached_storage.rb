require 'helper'

require 'dalli'

class TestMemcachedStorage < Test::Unit::TestCase
  def setup
    my_cache = Dalli::Client.new 'localhost:11211'
    my_cache.flush
    LockMethod.config.storage = my_cache
  end
    
  include SharedTests
end
