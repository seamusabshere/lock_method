require 'tmpdir'
require 'fileutils'
require 'thread'
module LockMethod
  class LockCollection
    class DefaultStorage
      def get(k)
        return unless ::File.exist? path(k)
        str = ::File.read path(k)
        expiry, v = ::Marshal.load str
        return if expiry.to_f < ::Time.now.to_f
        v
      rescue ::Errno::ENOENT
      end
    
      def set(k, v, ttl)
        semaphore.synchronize do
          ::File.open(path(k), ::File::RDWR|::File::CREAT) do |f|
            f.flock ::File::LOCK_EX
            expiry = (ttl == 0) ? 0 : ::Time.now + ttl
            f.write ::Marshal.dump([expiry, v])
          end
        end
      end
    
      def delete(k)
        ::FileUtils.rm_f path(k)
      end
    
      def flush
        ::FileUtils.rm_rf dir
      end
    
      private
    
      def semaphore
        @semaphore ||= ::Mutex.new
      end
    
      def path(k)
        ::File.join dir, k
      end
    
      def dir
        dir = ::File.expand_path(::File.join(::Dir.tmpdir, 'lock_method'))
        ::FileUtils.mkdir_p dir unless ::File.directory? dir
        dir
      end
    end
  end
end
