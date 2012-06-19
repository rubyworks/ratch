module Ratch

  require 'rbconfig'

  # ShellUtils provides the whole slew of FileUtils,
  # FileTest and File class methods in a single module
  # and modifies methods according to noop? and verbose?
  # options.
  module ShellUtils

    #
    def verbose?
      false
    end

    #
    def noop?
      false
    end

    #
    def dryrun?
      noop? && verbose?
    end

    #
    def force?
      false
    end

    # A path is required for shell methods to operate.
    # If no path is set than the current working path is used.
    def path
      @path ||= Dir.pwd
    end

    # Set shell path.
    def path=(dir)
      @path = dir
    end

    attr_writer :force
    attr_writer :quiet
    attr_writer :trace
    attr_writer :trial
    attr_writer :debug
    attr_writer :verbose

    def force?   ; @force   ; end

    def quiet?   ; @quiet   ; end
    def trial?   ; @trial   ; end

    def trace?   ; @trace   ; end
    def debug?   ; @debug   ; end

    def verbose? ; @verbose ; end
    def noop?    ; @trial   ; end
    def dryrun?  ; verbose? && noop? ; end

    def silent?  ; @quiet   ; end

    # -- Shell ----------------------------------------------------------------

    # Delegate to Ratch::Shell instance.
    #def shell(path=Dir.pwd)
    #  @shell ||= {}
    #  @shell[path] ||= (
    #    mode = {
    #      :noop    => trial?,
    #      :verbose => trace? || (trial? && !quiet?),
    #      :quiet   => quiet?
    #    }
    #    Ratch::Shell.new(path, mode)
    #  )
    #end

    # Shell runner.
    def sh(cmd)
      trace cmd
      return true if noop?

      if quiet?
        silently{ system(cmd) }
      else
        system(cmd)
      end
    end

    # Current ruby binary.
    RUBY = (
      bindir   = ::Config::CONFIG['bindir']
      rubyname = ::Config::CONFIG['ruby_install_name']
      File.join(bindir, rubyname}.sub(/.*\s.*/m, '"\&"')
    )

    # Shell-out to ruby.
    def ruby(cmd)
      sh RUBY + " " + cmd
    end

=begin
    # -- Dir Methods ----------------------------------------------------------

    # TODO: Ultimately merge #glob and #multiglob.
    def multiglob(*args, &blk)
      Dir.multiglob(*args, &blk)
    end

    #
    def multiglob_r(*args, &blk)
      Dir.multiglob_r(*args, &blk)
    end
=end

    # -- File Testing ---------------------------------------------------------

    def size(path)             ; FileTest.size(path)             ; end
    def size?(path)            ; FileTest.size?(path)            ; end
    def directory?(path)       ; FileTest.directory?(path)       ; end
    def symlink?(path)         ; FileTest.symlink?(path)         ; end
    def readable?(path)        ; FileTest.readable?(path)        ; end
    def chardev?(path)         ; FileTest.chardev?(path)         ; end
    def exist?(path)           ; FileTest.exist?(path)           ; end
    def exists?(path)          ; FileTest.exists?(path)          ; end
    def zero?(path)            ; FileTest.zero?(path)            ; end
    def pipe?(path)            ; FileTest.pipe?(path)            ; end
    def file?(path)            ; FileTest.file?(path)            ; end
    def sticky?(path)          ; FileTest.sticky?(path)          ; end
    def blockdev?(path)        ; FileTest.blockdev?(path)        ; end
    def grpowned?(path)        ; FileTest.grpowned?(path)        ; end
    def setgid?(path)          ; FileTest.setgid?(path)          ; end
    def setuid?(path)          ; FileTest.setuid?(path)          ; end
    def socket?(path)          ; FileTest.socket?(path)          ; end
    def owned?(path)           ; FileTest.owned?(path)           ; end
    def writable?(path)        ; FileTest.writable?(path)        ; end
    def executable?(path)      ; FileTest.executable?(path)      ; end

    def safe?(path)            ; FileTest.safe?(path)            ; end

    def relative?(path)        ; FileTest.relative?(path)        ; end
    def absolute?(path)        ; FileTest.absolute?(path)        ; end

    def writable_real?(path)   ; FileTest.writable_real?(path)   ; end
    def executable_real?(path) ; FileTest.executable_real?(path) ; end
    def readable_real?(path)   ; FileTest.readable_real?(path)   ; end

    def identical?(path, other)
      FileTest.identical?(path, other)
    end

    alias_method :compare_file, :identical?

    # -- File Methods ---------------------------------------------------------

    def atime(*args) ; File.ctime(*args) ; end
    def ctime(*args) ; File.ctime(*args) ; end
    def mtime(*args) ; File.mtime(*args) ; end

    def utime(*args)
      $stderr.puts "utime #{args.join(' ')}" if verbose?
      File.utime(*args) unless noop?
    end

    # -- File IO Shortcuts ----------------------------------------------------

    # Read file.
    def read(path)
      File.read(path)
    end

    # Write file.
    #
    # @TODO should this be 'wb' mode?
    def write(path, text)
      $stderr.puts "write #{path}" if verbose?
      File.open(path, 'w'){ |f| f << text } unless noop?
    end

    # Append to file.
    def append(path, text)
      $stderr.puts "append #{path}" if verbose?
      File.open(path, 'a'){ |f| f << text } unless noop?
    end

    private # -----------------------------------------------------------------

    # Returns FileUtils module based on mode.
    def fileutils
      if dryrun?
        ::FileUtils::DryRun
      elsif noop?
        ::FileUtils::Noop
      elsif verbose?
        ::FileUtils::Verbose
      else
        ::FileUtils
      end
    end

  end

end
