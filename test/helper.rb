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
    sleep 2
    ["hello from #{name}"]
  end
  lock_method :get_latest_entries
  def get_latest_entries2
    sleep 8
    ["voo vaa #{name}"]
  end
  lock_method :get_latest_entries2, 5 # second
  def marshal_dump
    raise "Used marshal_dump"
  end
  def as_lock
    name
  end
end

class Blog1a < Blog1
  def as_lock
    raise "Used as_lock"
  end
end

class Blog2
  class << self
    def get_latest_entries
      sleep 2
      'danke schoen'
    end
    lock_method :get_latest_entries
    def get_latest_entries2
      sleep 8
      ["voo vaa #{name}"]
    end
    lock_method :get_latest_entries2, 5 # second
    def work_really_hard_on(target)
      sleep 2
      target.to_s
    end
    lock_method :work_really_hard_on
  end
end

module BlogM
  def self.get_latest_entries
    sleep 2
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

module BlogSpin
  def self.get_latest_entries
    sleep 2
    'danke schoen'
  end
  class << self
    lock_method :get_latest_entries, :spin => true
  end
end

class Test::Unit::TestCase

end
