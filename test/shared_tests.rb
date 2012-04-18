def new_instance_of_my_blog
  Blog1.new 'my_blog', 'http://my_blog.example.com'
end
def new_instance_of_another_blog
  Blog1.new 'another_blog', 'http://another_blog.example.com'
end

module SharedTests
  def test_01_locked_method_return_value
    assert_equal ["hello from my_blog"], new_instance_of_my_blog.get_latest_entries
  end
  
  def test_02_locked_by_normally_terminating_process
    pid = Kernel.fork { Blog2.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
  
    # let the blocker finish
    Process.wait pid
    
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
  end
  
  def test_03_module_method_locked_by_normally_terminating_process
    pid = Kernel.fork { BlogM.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      BlogM.get_latest_entries
    end
  
    # let the blocker finish
    Process.wait pid
    
    assert_nothing_raised do
      BlogM.get_latest_entries
    end
  end
  
  def test_06_locked_by_normally_finishing_thread
    blocker = Thread.new { Blog2.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
  
    # wait to finish
    blocker.join
    
    # now we're sure
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
  end
  
  def test_07_lock_instance_method
    pid = Kernel.fork { new_instance_of_my_blog.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      new_instance_of_my_blog.get_latest_entries
    end
  
    # wait for it
    Process.wait pid
    
    # ok now
    assert_nothing_raised do
      new_instance_of_my_blog.get_latest_entries
    end
  end
  
  def test_08_instance_method_lock_is_unique_to_instance
    pid = Kernel.fork { new_instance_of_my_blog.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_nothing_raised do
      new_instance_of_another_blog.get_latest_entries
    end
  
    Process.wait pid
  end
  
  def test_09_clear_instance_method_lock
    pid = Kernel.fork { new_instance_of_my_blog.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      new_instance_of_my_blog.get_latest_entries
    end
  
    # but now we clear the lock
    new_instance_of_my_blog.lock_method_clear :get_latest_entries
    assert_nothing_raised do
      new_instance_of_my_blog.get_latest_entries
    end
    
    Process.wait pid
  end
  
  def test_10_clear_class_method_lock
    pid = Kernel.fork { Blog2.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
    
    # but now we clear the lock
    Blog2.lock_method_clear :get_latest_entries
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
    
    Process.wait pid
  end
  
  def test_11_expiring_lock
    pid = Kernel.fork { Blog2.get_latest_entries2 }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries2
    end
  
    # still no...
    sleep 1
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries2
    end
    
    # but the lock expiry is 5 seconds, so by 5.2&change we're done
    sleep 3.2
    assert_nothing_raised do
      Blog2.get_latest_entries2
    end
    
    Process.wait pid
  end
  
  def test_12_locked_according_to_method_arguments
    pid = Kernel.fork { Blog2.work_really_hard_on :foo }
  
    # give it a bit of time to lock
    sleep 1
        
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.work_really_hard_on :foo
    end
  
    # let the blocker finish
    Process.wait pid
    
    assert_nothing_raised do
      Blog2.work_really_hard_on :foo
    end
  end
  
  def test_13_no_encoding_issues
    old_int = Encoding.default_internal
    old_ext = Encoding.default_external
    Encoding.default_internal = 'UTF-8'
    Encoding.default_external = 'UTF-8'
    assert_equal ["hello from my_blog"], new_instance_of_my_blog.get_latest_entries
  ensure
    Encoding.default_internal = old_int
    Encoding.default_external = old_ext
  end
  
  def test_14_spin
    pid = Kernel.fork { BlogSpin.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    assert_equal 'danke schoen', BlogSpin.get_latest_entries
  end

  def test_15_block
    blocker = Thread.new do
      BlogBlock.get_latest_entries { $stderr.write "i'm in the way!" }
    end
    
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      BlogBlock.get_latest_entries { $stderr.write "don't print me" }
    end
    
    # wait to finish
    blocker.join
    
    # now we're sure
    assert_nothing_raised do
      BlogBlock.get_latest_entries { $stderr.write "i'm now allowed" }
    end
  end
end
