require 'tmpdir'
require 'fileutils'
require 'thread'
module LockMethod
  class Storage
    class DefaultStorageClient
      def get(k)
        return unless ::File.exist? path(k)
        ::Marshal.load ::File.read(path(k))
      rescue ::Errno::ENOENT
      end
    
      def set(k, v, ttl)
        semaphore.synchronize do
          ::File.open(path(k), ::File::RDWR|::File::CREAT) do |f|
            f.flock ::File::LOCK_EX
            f.write ::Marshal.dump(v)
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
