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
    sleep 2
    ["voo vaa #{name}"]
  end
  lock_method :get_latest_entries2, 1 # second
end

class Blog2
  class << self
    def get_latest_entries
      sleep 2
      'danke schoen'
    end
    lock_method :get_latest_entries
    def get_latest_entries2
      sleep 2
      ["voo vaa #{name}"]
    end
    lock_method :get_latest_entries2, 1 # second
  end
end

def new_instance_of_my_blog
  Blog1.new 'my_blog', 'http://my_blog.example.com'
end
def new_instance_of_another_blog
  Blog1.new 'another_blog', 'http://another_blog.example.com'
end

class Test::Unit::TestCase

end
