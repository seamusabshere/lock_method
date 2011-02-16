require 'tmpdir'
require 'fileutils'
module LockMethod
  class DefaultClient
    def get(k)
      return unless ::File.exist? path(k)
      str = ::File.read path(k)
      expiry, v = ::Marshal.load str
      return if expiry.to_f < ::Time.now.to_f
      v
    end
    
    def set(k, v, ttl)
      ::File.open(path(k), 'w') do |f|
        expiry = (ttl == 0) ? 0 : ::Time.now + ttl
        f.write ::Marshal.dump([expiry, v])
      end
    end
    
    def delete(k)
      ::FileUtils.rm_f path(k)
    end
    
    def flush
      ::FileUtils.rm_rf dir
    end
    
    private
    
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
