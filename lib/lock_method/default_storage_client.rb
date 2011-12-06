require 'singleton'
require 'tmpdir'
require 'fileutils'
require 'thread'
module LockMethod
  class DefaultStorageClient #:nodoc: all

    include ::Singleton

    class Entry
      attr_reader :created_at
      attr_reader :ttl
      attr_reader :v
      def initialize(ttl, v)
        @created_at = ::Time.now.to_f
        @ttl = ttl
        @v = v
      end
      def expired?
        ttl.to_i > 0 and (::Time.now.to_f - created_at.to_f) > ttl.to_i
      end
    end

    def get(k)
      if ::File.exist?(path(k)) and entry = ::Marshal.load(::File.read(path(k))) and not entry.expired?
        entry.v
      end
    rescue ::Errno::ENOENT
    end
  
    def set(k, v, ttl)
      entry = Entry.new ttl, v
      semaphore.synchronize do
        ::FileUtils.mkdir_p dir unless ::File.directory? dir
        ::File.open(path(k), ::File::RDWR|::File::CREAT, :external_encoding => 'ASCII-8BIT') do |f|
          f.flock ::File::LOCK_EX
          f.write ::Marshal.dump(entry)
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
      ::File.expand_path ::File.join(::Dir.tmpdir, 'lock_method')
    end
  end
end
