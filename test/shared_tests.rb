module SharedTests
  def test_locked_method_return_value
    assert_equal ["hello from my_blog"], new_instance_of_my_blog.get_latest_entries
  end
  
  def test_locked_by_normally_terminating_process
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
  
  def test_locked_by_SIGKILLed_process
    pid = Kernel.fork { Blog2.get_latest_entries }
    
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
  
    # kill it and then wait for it to be reaped
    Process.detach pid
    Process.kill 9, pid
    sleep 1
    
    # now we're sure
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
  end
  
  def test_locked_by_killed_thread
    blocker = Thread.new { Blog2.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
  
    # kinda like a SIGKILL
    blocker.kill
    
    # now we're sure
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
  end
  
  def test_locked_by_normally_finishing_thread
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
  
  def test_lock_instance_method
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
  
  def test_clear_instance_method_lock
    pid = Kernel.fork { new_instance_of_my_blog.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      new_instance_of_my_blog.get_latest_entries
    end
  
    # but now we clear the lock
    new_instance_of_my_blog.clear_lock :get_latest_entries
    assert_nothing_raised do
      new_instance_of_my_blog.get_latest_entries
    end
    
    Process.wait pid
  end
  
  def test_clear_class_method_lock
    pid = Kernel.fork { Blog2.get_latest_entries }
  
    # give it a bit of time to lock
    sleep 1
    
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
    
    # but now we clear the lock
    Blog2.clear_lock :get_latest_entries
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
    
    Process.wait pid
  end
  
  def test_expiring_lock
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
    
    # but the lock expiry is 1 second, so by 1.2&change we're done
    sleep 5
    assert_nothing_raised do
      Blog2.get_latest_entries2
    end
    
    Process.wait pid
  end
end
