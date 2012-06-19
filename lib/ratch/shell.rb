require 'thread'
#require 'rbconfig'
require 'ratch/core_ext'
require 'ratch/batch'

module Ratch

  # TODO: Better base class?
  class FileNotFound < StandardError
  end

  # = Shell Prompt class
  #
  # Ratch Shell object provides a limited file system shell in code.
  # It is similar to having a shell prompt available to you in Ruby.
  #
  # NOTE: We have used the term *trace* in place of *verbose* for command
  # line options. Even though Ruby itself uses the term *verbose* with respect
  # to FileUtils, the term is commonly used for command specific needs, so we
  # want to leave it open for such cases.
  class Shell

    #
    def self.[](path)
      new(path)
    end

    # New Shell object.
    #
    #   Shell.new(:noop=>true)
    #   Shell.new('..', :quiet=>true)
    #
    def initialize(*args)
      path, opts = parse_arguments(*args)

      opts.rekey!(&:to_sym)

      set_options(opts)

      if path.empty?
        path = Dir.pwd
      else
        path = File.join(*path)
      end

      raise FileNotFound, "#{path}" unless ::File.exist?(path)
      raise FileNotFound, "#{path}" unless ::File.directory?(path)

      @_work = Pathname.new(path).expand_path
    end

    private

    #
    def parse_arguments(*args)
      opts = (Hash===args.last ? args.pop : {})
      return args, opts
    end

    #
    def set_options(opts)
      @_quiet   = opts[:quiet]   || options[:silent]
      @_nowrite = opts[:nowrite] || options[:noop]    || opts[:dryrun]
      @_trace   = opts[:trace]   || options[:verbose] || opts[:dryrun]
      #@_force = opts[:force]
    end

    #
    def mutex
      @mutex ||= Mutex.new
    end

    public

    # Opertaton mode. This can be :noop, :verbose or :dryrun.
    # The later is the same as the first two combined.
    #def mode(opts=nil)
    #  return @mode unless opts
    #  opts.each do |key, val|
    #    next unless val
    #    case key
    #    when :noop
    #      @mode = (@mode == :verbose ? :dryrun : :noop)
    #    when :verbose
    #      @mode = (@mode == :noop ? :dryrun : :verbose)
    #    when :dryrun
    #      @mode = :dryrun
    #    end
    #  end
    #end

    def quiet?   ; @_quiet   ; end
    def trace?   ; @_trace   ; end
    def nowrite? ; @_nowrite ; end
    #def force?  ; @_force ; end

    def dryrun?  ; nowrite? && trace? ; end

    alias verbose? trace?
    alias noop? nowrite

    # String representation is work directory path.
    def to_s ; work.to_s ; end

    # Two Shell's are equal if they have the same working path.
    def ==(other)
      return false unless other.is_a?(self.class)
      return false unless work == other.work
      true
    end

    # Same as #== except that #noop? must also be the same.
    def eql?(other)
      return false unless other.is_a?(self.class)
      return false unless work == other.work
      return false unless noop?  == other.noop?
      true
    end

    # Provides convenient starting points in the file system.
    #
    #   root   #=> #<Pathname:/>
    #   home   #=> #<Pathname:/home/jimmy>
    #   work   #=> #<Pathname:/home/jimmy/Documents>
    #

    # Current root path.
    #def root(*args)
    #  Pathname['/', *args]
    #end

    # Current home path.
    #def home(*args)
    #  Pathname['~', *args].expand_path
    #end

    # Current working path.
    #def work(*args)
    #  Pathname['.', *args]
    #end

  # TODO: Should these take *args?

    # Root location.
    def root(*args)
      dir('/', *args)
    end

    # Current home path.
    def home(*args)
      dir(File.expand_path('~'), *args)
    end

    # Current working path.
    def work(*args)
      return @_work if args.empty?
      return dir(@_work, *args)
    end

    # Alias for #work.
    #alias_method :pwd, :work

    # Return a new prompt with the same location.
    # NOTE: Use #dup or #clone ?
    #def new ; Shell.new(work) ; end

    def parent
      dir('..')
    end

    #
    #def [](name)
    #  #FileObject[localize(name)]
    #  #Pathname.new(localize(path))
    #  Pathlist.new(localize(path))
    #end

    # Returns a Batch of file +patterns+.
    def batch(*patterns)
      Batch.new patterns.map{|pattern| localize(pattern)}
    end

    # Returns a Batch of file +patterns+, without any exclusions.
    def batch_all(*patterns)
      Batch.all patterns.map{|pattern| localize(pattern)}
    end

    #
    def path(path)
      Pathname.new(localize(path))
    end
    alias_method :pathname, :path

    #
    def file(path)
      #FileObject[name]
      path = localize(path)
      raise FileNotFound unless File.file?(path)
      Pathname.new(path)
    end

    #def doc(name)
    #  Document.new(name)
    #end

    #
    def dir(path)
      #Directory.new(name)
      path = localize(path)
      raise FileNotFound unless File.directory?(path)
      Pathname.new(path)
    end

    # Lists all entries.
    def entries
      work.entries
    end

    #alias_method :ls, :entries

    # Lists directory entries.
    def directory_entries
      entries.select{ |d| d.directory? }
    end

    #
    alias_method :dir_entries, :directory_entries

    # Lists file entries.
    def file_entries
      entries.select{ |f| f.file? }
    end

    # Likes entries but omits '.' and '..' paths.
    def pathnames
      work.entries - %w{. ..}.map{|f|Pathname.new(f)}
    end

    # Returns list of directories.
    def directories
      pathnames.select{ |f| f.directory? }
    end
    alias_method :dirs, :directories
    alias_method :folders, :directories

    # Returns list of files.
    def files
      pathnames.select{ |f| f.file? }
    end

    # Join paths.
    #--
    # TODO: Should this return a new directory object?
    # Or should it change directories?
    #++
    def /(path)
      #@_work += dir   # did not work, why?
      @_work = dir(localize(path))
      self
    end

    # Alias for #/.
    alias_method '+', '/'

    #--
    # TODO: Tie system into the System class (?)
    #++
    def system(cmd)
      locally do
        super(cmd)
      end
    end

    # Shell runner.
    def sh(cmd)
      #puts "--> system call: #{cmd}" if trace?
      puts cmd if trace?
      return true if noop?
      #locally do
        if quiet?
          silently{ system(cmd) }
        else
          system(cmd)
        end
      #end
    end

    # Shell runner.
    #def sh(cmd)
    #  if dryrun?
    #    puts cmd
    #    true
    #  else
    #    puts "--> system call: #{cmd}" if trace?
    #    if quiet?
    #      silently{ system(cmd) }
    #    else
    #      system(cmd)
    #    end
    #  end
    #end

    # Change working directory.
    #
    # TODO: Make thread safe.
    #
    def cd(path, &block)
      if block
        work_old = @_work
        begin
          @_work = dir(localize(path))
          locally(&block)
          #mutex.synchronize do
          #  Dir.chdir(@_work){ block.call }
          #end
        ensure
          @_work = work_old
        end
      else
        @_work = dir(localize(path))
      end
    end

    #
    alias_method :chdir, :cd

    # Bonus FileUtils features.
    #def cd(*a,&b)
    #  puts "cd #{a}" if dryrun? or trace?
    #  fileutils.chdir(*a,&b)
    #end

    # Methods that can simply be localized via their first argument.

    LOCALIZABLE_METHODS = %w{
      size size? directory? dir? readable? symlink? chardev? exist? exists?
      zero? pipe? file? stticky? blockdev? grpowned? setgid? setuid?
      socket? owned? writable? executable? safe? readable_real?
      writeable_real? executable_real? 
    }

    LOCALIZABLE_METHODS.each do |name|
      module_eval %{
        def #{name}(path)
          shellutils.#{name}(localize(path))
        end
      }
    end

    def relative?(path); shellutils.relative?(path); end
    def absolute?(path); shellutils.absolute?(path); end

    def identical?(path, other)
      shellutils.indentical?(localize(path), localize(other))
    end

    alias_method :cmp, :identical?

    #alias_method :directory?, :dir? #; module_function :directory?


    # Methods that are wrapped in a locally chdir block.

    LOCALLY_METHODS = %w{
      mkdir mkdir_p mkpath rmdir ln ln_s ln_sf link symlink 
      cp cp_r copy mv move rm rm_r rm_f rm_rf remove
      install chmod chmod_r chmod_R chown chown_r chown_R touch
      stage amass uptodate? outofdate?
      ctime atime mtime utime
      read write append glob
      multiglob multiglob_r
    }

    LOCALLY_METHODS.each do |name|
      module_eval %{
        def #{name}(*args)
          locally do
            super(*args)
          end
        end
      }
    end

    # These low-level Fileutils methods have omitted.
    #
    # * getwd           -> pwd
    # * compare_file    -> cmp
    # * remove_file     -> rm
    # * copy_file       -> cp
    # * remove_dir      -> rmdir
    # * safe_unlink     -> rm_f
    # * makedirs        -> mkdir_p
    # * rmtree          -> rm_rf
    # * copy_stream
    # * remove_entry
    # * copy_entry
    # * remove_entry_secure
    # * compare_stream

    # Present working directory.
    def pwd
      work.to_s
    end

    #
    # TODO: should this have SOURCE diectory?
    #   stage(directory, source_dir, files)
    #
    def stage(stage_dir, files)
      #dir   = localize(directory)
      #files = localize(files)
      locally do
        fileutils.stage(stage_dir, work, files)
      end
    end

  private

    # Returns a path local to the current working path.
    def localize(local_path)
      # some path arguments are optional
      return local_path unless local_path
      #
      case local_path
      when Array
        local_path.collect do |lp|
          if absolute?(lp)
            lp
          else
            File.expand_path(File.join(work.to_s, lp))
          end
        end
      else
        # do not localize an absolute path
        return local_path if absolute?(local_path)
        File.expand_path(File.join(work.to_s, local_path))
        #(work + local_path).expand_path.to_s
      end
    end

    # Change directory to the shell's work directory,
    # process the +block+ and then return to user directory.
    def locally(&block)
      if work.to_s == Dir.pwd
        block.call
      else
        mutex.synchronize do
          #work.chdir(&block)
          Dir.chdir(work, &block)
        end
      end
    end

    # TODO: Should naming policy be in a utility extension module?

    #
    #
    def naming_policy(*policies)
      if policies.empty?
        @naming_policy ||= ['down', 'ext']
      else
        @naming_policy = policies
      end
    end

    #
    #
    def apply_naming_policy(name, ext)
      naming_policy.each do |policy|
        case policy.to_s
        when /^low/, /^down/
          name = name.downcase
        when /^up/
          name = name.upcase
        when /^cap/
          name = name.capitalize
        when /^ext/
          name = name + ".#{ext}"
        end
      end
      name
    end

  private

    # The ShellUtils module based on current mode.
    def shellutils
      if dryrun?
        ShellUtils::DryRun
      elsif nowrite?
        ShellUtils::NoWrite
      elsif trace?
        ShellUtils::Verbose
      else
        ShellUtils
      end
    end

    # TODO: What's #util_options for?

    # This may be used by script commands to allow for per command
    # noop and trace options. Global options have precedence.
    def util_options(options)
      noop  = noop?  || options[:noop]  || options[:dryrun]
      trace = trace? || options[:trace] || options[:dryrun]
      return noop, trace
    end

#    # Returns FileUtils module based on mode.
#    def fileutils
#      if dryrun?
#        ::FileUtils::DryRun
#      elsif noop?
#        ::FileUtils::NoWrite
#      elsif trace?
#        ::FileUtils::Verbose
#      else
#        ::FileUtils
#      end
#    end

#    # Does a path need updating, based on given +sources+?
#    # This compares mtimes of give paths. Returns false
#    # if the path needs to be updated.
#    #
#    # TODO: Put this in FileTest instead?
#
#    def out_of_date?(path, *sources)
#      return true unless File.exist?(path)
#
#      sources = sources.collect{ |source| Dir.glob(source) }.flatten
#      mtimes  = sources.collect{ |file| File.mtime(file) }
#
#      return true if mtimes.empty?  # TODO: This the way to go here?
#
#      File.mtime(path) < mtimes.max
#    end

  end

end

