require 'tmpdir'
require 'fileutils'
require 'digest/sha1'

module LockMethod
  class DefaultStorageClient #:nodoc: all
    class Entry
      attr_reader :created_at
      attr_reader :ttl
      attr_reader :v
      def initialize(v, ttl)
        @created_at = ::Time.now
        @ttl = ttl.to_f
        @v = v
      end
      def expired?
        ttl > 0 and (::Time.now - created_at) > ttl
      end
    end

    DIR = ::File.join ::Dir.tmpdir, 'lock_method'

    def initialize
      @mutex = ::Mutex.new
      ::FileUtils.mkdir(DIR) unless ::File.directory?(DIR)
    end

    def get(k)
      path = path k
      @mutex.synchronize do
        if ::File.exist?(path) and (entry = ::Marshal.load(::File.read(path))) and not entry.expired?
          entry.v
        end
      end
    rescue
      $stderr.puts %{[lock_method] Rescued from #{$!.inspect} while trying to get a lock}
    end
  
    def set(k, v, ttl)
      entry = Entry.new v, ttl
      @mutex.synchronize do
        ::File.open(path(k), 'wb') do |f|
          f.flock ::File::LOCK_EX
          f.write ::Marshal.dump(entry)
        end
      end
    end
  
    def delete(k)
      ::FileUtils.rm_f path(k)
    end
  
    def flush
      ::Dir["#{DIR}/*.lock"].each do |path|
        ::FileUtils.rm_f path
      end
    end

    private

    def path(k)
      ::File.join DIR, "#{::Digest::SHA1.hexdigest(k)}.lock"
    end
  end
end
