require 'enumerator'
require 'fileutils'

#class Enumerator
#  alias_method :list, :to_a
#end


module Folio

  # = File Object
  #
  # Base class for all folio objects.

  class FileObject

    Separator = ::File::Separator

    # Factory method.
    def self.[](*path)
      path = ::File.join(*path)

      #raise FileNotFound.new(path) unless ::File.exist?(path)
      if !File.exist?(path)
        return Pathname.new(path)
      end

      case ::File.ftype(path)
      when 'file'
        Document.new(path)
      when 'directory'
        Directory.new(path)
      when 'link'
        Link.new(path)
      when 'characterSpecial'
        CharacterDevice.new(path)
      when 'blockSpecial'
        BlockDevice.new(path)
      when 'socket'
        raise TypeError # Socket.new(path) ?
      when 'fifo'
        raise TypeError # Pipe?
      else # 'unknown'
        raise FileNotFound.new(path)
      end
    end

  private

    def initialize(path)
      @path = ::File.expand_path(path)
      assert_exists if ::File.exist?(@path)
    end

    def assert_exists
    end

  public

    attr :path

    def ==(other)
#p @path, other.path
      return false unless FileObject===other
      @path == other.path
    end

    # This will alwasy be true, EXCEPT when
    # #rm, #delete or #unlink have been used.
    def exist?
      ::FileTest.exist?(path)
    end
    alias_method :exists?, :exist?

    # Returns the parent directory object.
    def parent
      self.class[File.dirname(path)]
    end

    #--
    # File Manipulation
    #++

    def link(new)
      ::File.ln(path, new)
    end
    alias_method :ln, :link

    def link_force(new)
      ::File.remove(new)
      link(new)
    end
    alias_method :ln_f, :link_force

    def symlink(new)
      ::File.symlink(path, new)
    end
    alias_method :ln_s, :symlink

    def symlink_force(new)
      ::File.remove(new)
      symlink(new)
    end
    alias_method :ln_sf, :symlink_force

    def rename(dest)
      ::File.rename(path, dest)
      @path = ::File.expand_path(dest)
    end
    alias_method :mv, :rename

    # how to handle --b/c it disappears?
    def unlink
      ::File.delete(path)
    end
    alias_method :delete, :unlink
    alias_method :rm, :unlink

    def unlink_force
      ::File.remove(new)
      unlink(path)
    end
    alias_method :delete_force, :unlink_force
    alias_method :rm_f, :unlink_force

    def chmod(mode)
      ::File.chmod(mode, path)
    end

    def chown(user, group)
      ::File.chown(user, group, path)
    end

    def utime(atime, mtime)
      ::File.utime(atime, mtime, path)
    end

    # Wherever possible we have tried to avoid using
    # FileUtils. Hoever there are a few methods that
    # require it's use becuase of the complications
    # in their implementation. Evenutlly we might port
    # these methods.

    # Copy file to destination path.
    def cp(dest)
      util.cp(path, dest)
    end

    # Install file to destination path.
    def install(dest, mode=nil)
      util.install(path, dest, mode)
    end

    #
    def touch
      util.touch(path)
    end

    # Status methods. These methods all access a cached
    # ::File::Stat object. You can use #stat! to refresh
    # the status cache.

    # Get stat and cache it.
    def stat
      @stat ||= File.stat(path)
    end

    # Refresh status cache.
    def restat
      @stat = File.stat(path)
    end
    alias_method :stat!, :restat

    #def file?               ; stat.file?             ; end
    def document?           ; stat.file?             ; end
    def directory?          ; stat.directory?        ; end
    def blockdev?           ; stat.blockdev?         ; end
    def chardev?            ; stat.chardev?          ; end
    def socket?             ; stat.socket?           ; end
    def pipe?               ; stat.pipe?             ; end

    def atime               ; stat.atime             ; end
    def ctime               ; stat.ctime             ; end
    def grpowned?           ; stat.grpowned?         ; end
    def identical?          ; stat.identical?        ; end
    def mtime               ; stat.mtime             ; end
    def owned?              ; stat.owned?            ; end
    def readable?           ; stat.readable?         ; end
    def readable_real?      ; stat.readable_real     ; end
    def setgid?             ; stat.setgid?           ; end
    def setuid?             ; stat.setuid?           ; end
    def size                ; stat.size              ; end
    def size?               ; stat.size?             ; end
    def sticky?             ; stat.sticky?           ; end
    def writable?           ; stat.writable?         ; end
    def writable_real?      ; stat.writable_real?    ; end
    def zero?               ; stat.zero?             ; end

    #--
    # Pathname Methods
    #++

    def basename            ; ::File.basename(path)              ; end
    def dirname             ; ::File.dirname(path)               ; end
    def extname             ; ::File.extname(path)               ; end

    # TODO: I don't like the name of this.
    def split               ; ::File.split(path)                 ; end

    # Gives path relative to current working directory.
    # If current is below path one step then it uses '..',
    # further below and it returns the full path.
    def relative
      pwd = Dir.pwd
      pth = path
      if pth.index(pwd) == 0
        r = pth[pwd.size+1..-1]
        r = '.' unless r
        return r
      else
        pwd = File.dirname(pwd)
        if pth.index(pwd) == 0
          r = pth[pwd.size+1..-1]
          return '..' unless r
          return File.join('..', r)
        else
          pth
        end
      end
    end

    def fnmatch(pattern, flags=0)
      ::File.fnmatch(path, pattern, flags)
    end
    alias_method :fnmatch?, :fnmatch

    #--
    # Standard Object Methods
    #++

    # Inspect returns the path string relative to
    # the current working directory.
    def inspect; "#{relative}"; end

    # Returns the path string.
    def to_s   ; path ; end
    def to_str ; path ; end

    def <=>(other)
      path <=> other.to_s
    end

    def ==(other)
      path == other.to_s
    end

  private

    def util
      ::FileUtils
    end

  end

end

