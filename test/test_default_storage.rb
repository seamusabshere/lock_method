require 'helper'

class TestDefaultStorageClient < Test::Unit::TestCase
  def setup
    LockMethod.config.storage = nil
    LockMethod.config.storage.flush
  end
  
  include SharedTests
end
