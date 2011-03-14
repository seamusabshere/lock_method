require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'ruby-debug'
require 'shared_tests'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lock_method'

class Blog1
  attr_reader :name
  attr_reader :url
  def initialize(name, url)
    @name = name
    @url = url
  end
  def get_latest_entries
    sleep 8
    ["hello from #{name}"]
  end
  lock_method :get_latest_entries
  def get_latest_entries2
    sleep 8
    ["voo vaa #{name}"]
  end
  lock_method :get_latest_entries2, 5 # second
  def hash
    raise "Used hash"
  end
  def method_lock_hash
    name.hash
  end
end

class Blog1a < Blog1
  def method_lock_hash
    raise "Used method_lock_hash"
  end
end

class Blog2
  class << self
    def get_latest_entries
      sleep 8
      'danke schoen'
    end
    lock_method :get_latest_entries
    def get_latest_entries2
      sleep 8
      ["voo vaa #{name}"]
    end
    lock_method :get_latest_entries2, 5 # second
  end
end

module BlogM
  def self.get_latest_entries
    sleep 8
    'danke schoen'
  end
  def self.get_latest_entries2
    sleep 8
    ["voo vaa #{name}"]
  end
  class << self
    lock_method :get_latest_entries
    lock_method :get_latest_entries2, 5 # second
  end
end

class Test::Unit::TestCase

end
