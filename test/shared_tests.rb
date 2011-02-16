module SharedTests
  def test_locked_method_return_value
    assert_equal ["hello from my_blog"], new_instance_of_my_blog.get_latest_entries
  end
  
  def test_class_methods_with_forking
    blocker = Kernel.fork { Blog2.get_latest_entries }
  
    # the blocker won't have finished
    sleep 0.2
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
  
    # the blocker will have finished
    sleep 3
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
  end
  
  def test_class_methods_with_threads
    blocker = Thread.new { Blog2.get_latest_entries }
  
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
  
    # now we're sure the blocker has finished
    blocker.kill
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
  end
  
  def test_class_methods_with_unkilled_threads
    blocker = Thread.new { Blog2.get_latest_entries }
  
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
  
    # the thread should be dead...
    sleep 3
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
  end
  
  def test_instance_methods_with_forking
    blocker = Kernel.fork { new_instance_of_my_blog.get_latest_entries }
  
    # the blocker won't have finished
    sleep 0.2
    assert_raises(LockMethod::Locked) do
      new_instance_of_my_blog.get_latest_entries
    end
  
    # the blocker will have finished
    sleep 3
    assert_nothing_raised do
      new_instance_of_my_blog.get_latest_entries
    end
  end
  
  def test_instance_methods_with_threads
    blocker = Thread.new { new_instance_of_my_blog.get_latest_entries }
  
    # the blocker won't have finished
    assert_raises(LockMethod::Locked) do
      new_instance_of_my_blog.get_latest_entries
    end
  
    # now we're sure the blocker has finished
    blocker.kill
    assert_nothing_raised do
      new_instance_of_my_blog.get_latest_entries
    end
    
    def test_instance_methods_with_unkilled_threads
      blocker = Thread.new { new_instance_of_my_blog.get_latest_entries }
  
      # the blocker won't have finished
      assert_raises(LockMethod::Locked) do
        new_instance_of_my_blog.get_latest_entries
      end
  
      # the thread should be dead...
      sleep 3
      assert_nothing_raised do
        new_instance_of_my_blog.get_latest_entries
      end
    end
  end
  
  def test_clear_instance_method_lock_with_forking
    blocker = Kernel.fork { new_instance_of_my_blog.get_latest_entries }
  
    # the blocker won't have finished
    sleep 0.2
    assert_raises(LockMethod::Locked) do
      new_instance_of_my_blog.get_latest_entries
    end
  
    # but now we clear the lock
    new_instance_of_my_blog.clear_lock :get_latest_entries
    assert_nothing_raised do
      new_instance_of_my_blog.get_latest_entries
    end
  end
  
  def test_clear_class_method_lock_with_forking
    blocker = Kernel.fork { Blog2.get_latest_entries }
  
    # the blocker won't have finished
    sleep 0.2
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries
    end
    
    # but now we clear the lock
    Blog2.clear_lock :get_latest_entries
    assert_nothing_raised do
      Blog2.get_latest_entries
    end
  end
  
  def test_expiring_class_method_locks_with_forking
    blocker = Kernel.fork { Blog2.get_latest_entries2 }

    # the blocker won't have finished
    sleep 0.2
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries2
    end

    # still no...
    sleep 0.2
    assert_raises(LockMethod::Locked) do
      Blog2.get_latest_entries2
    end
    
    # but the lock expiry is 1 second, so by 1.4&change we're done
    sleep 1
    assert_nothing_raised do
      Blog2.get_latest_entries2
    end
  end
end
