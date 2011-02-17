require 'helper'

class TestDefaultStorageClient < Test::Unit::TestCase
  def setup
    LockMethod.config.storage = nil
    LockMethod.storage.flush
  end
  
  include SharedTests
end
