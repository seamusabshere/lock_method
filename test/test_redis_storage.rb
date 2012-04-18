require 'helper'

require 'redis'
require 'redis-namespace'
require 'uri'

class TestRedisStorage < Test::Unit::TestCase
  def setup
    # uri = URI.parse(ENV["REDIS_URL"])
    r = Redis.new#(:host => uri.host, :port => uri.port, :password => uri.password)
    my_cache = Redis::Namespace.new(:test_lock_method, :redis => r)
    LockMethod.config.storage = my_cache
  end
  
  include SharedTests
end
