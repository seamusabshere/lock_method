require 'helper'

if ENV['REDIS_URL']
  require 'redis'
  require 'uri'

  class TestRedisStorage < Test::Unit::TestCase
    def setup
      uri = URI.parse(ENV["REDIS_URL"])
      LockMethod.config.storage = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      LockMethod.lock_collection.flush
    end
    
    include SharedTests
  end
end
