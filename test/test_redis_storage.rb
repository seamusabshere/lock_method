require 'helper'

if ENV['REDIS_URL']
  require 'redis'
  require 'uri'

  class TestRedisStorage < Test::Unit::TestCase
    def setup
      uri = URI.parse(ENV["REDIS_URL"])
      my_cache = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      my_cache.flushdb
      LockMethod.config.storage = my_cache
    end
    
    include SharedTests
  end
end
