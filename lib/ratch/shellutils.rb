module Ratch

  module ShellUtils

    module Verbose
      include FileUtils::Verbose
      include ShellUtils
      extend self
    end

    module NoWrite
      include FileUtils::NoWrite
      include ShellUtils
      extend self
    end

    module DryRun
      include FileUtils::DryRun
      include ShellUtils
      extend self
    end

    private

    #
    def self.alias_options(name, *options)
      options.each do |option|
        case option
        when :verbose
          Verbose.module_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def #{name}(*args)
              super(*fu_update_option(args, :verbose => true))
            end
            #private :#{name}
          EOS
        when :noop
          NoWrite.module_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def #{name}(*args)
              super(*fu_update_option(args, :noop => true))
            end
            #private :#{name}
          EOS
          DryRun.module_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def #{name}(*args)
              super(*fu_update_option(args, :noop => true, :verbose => true))
            end
            #private :#{name}
          EOS
        else

        end
      end      
    end

    # -- FileTest Methods --

    def size(path)             ; FileTest.size(path)             ; end
    def size?(path)            ; FileTest.size?(path)            ; end
    def directory?(path)       ; FileTest.directory?(path)       ; end
    def dir?(path)             ; FileTest.directory?(path)       ; end
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
    alias_method :cmp, :identical?

    # -- File Methods --

    # Get creation timestamp.
    def ctime(*args)
      File.ctime(*args)
    end

    # Get or set last access timestamp.
    def atime(file, time=nil, opts={})
      opts, time = time, nil if Hash === time
      if time
        utime(time, file, opts)
      else
        File.atime(file)
      end
    end

    alias_options(:atime, :noop, :verbose)

    #
    def mtime(file, time=nil, opts={})
      opts, time = time, nil if Hash === time
      if time
        utime(time, time, file, opts)
      else
        File.mtime(file)
      end
    end

    alias_options(:mtime, :noop, :verbose)

    # @TODO format atime and mtime whe printing
    def utime(atime, mtime, *files)
      opts = {}
      opts = files.pop if Hash === files.last
      $stderr.puts "utime #{atime} #{mtime} #{files.join(' ')}" if opts[:verbose]
      File.utime(atime, mtime, *files) unless opts[:noop]
    end

    alias_options(:utime, :noop, :verbose)

    # Read file.
    def read(path)
      File.read(path)
    end

    # Write file.
    # @TODO should this be 'wb' mode?
    def write(path, text, opts={})
      $stderr.puts "write #{path}" if opts[:verbose]
      File.open(path, 'w'){ |f| f << text } unless opts[:noop]
    end

    alias_options(:write, :noop, :verbose)

    # Append to file.
    def append(path, text, opts={})
      $stderr.puts "append #{path}" if opts[:verbose]
      File.open(path, 'a'){ |f| f << text } unless opts[:noop]
    end

    alias_options(:append, :noop, :verbose)

    # -- Dir --

    # Glob pattern. Returns matches as strings.
    def glob(*patterns, &block)
      opts = (::Integer===patterns.last ? patterns.pop : 0)
      matches = []
      patterns.each do |pattern|
        matches.concat(Dir.glob(pattern, opts))
      end
      if block_given?
        matches.each(&block)
      else
        matches
      end
    end

    # TODO: Ultimately merge #glob and #multiglob.
    def multiglob(*args, &blk)
      Dir.multiglob(*args, &blk)
    end

    #
    def multiglob_r(*args, &blk)
      Dir.multiglob_r(*args, &blk)
    end

  end

end
