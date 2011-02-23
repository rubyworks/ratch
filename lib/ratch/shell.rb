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
      @_quiet = opts[:quiet]
      @_noop  = opts[:noop]  || opts[:dryrun]
      @_trace = opts[:trace] || opts[:dryrun]
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

    def quiet?   ; @_quiet ; end
    def trace?   ; @_trace ; end
    def noop?    ; @_noop  ; end
    #def force?  ; @_force ; end

    def dryrun?  ; noop? && trace? ; end

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
    # TODO: Replace these with Folio when Folio's is as capable.

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

    # Glob pattern. Returns matches as strings.
    def glob(*patterns, &block)
      opts = (::Integer===patterns.last ? patterns.pop : 0)
      matches = []
      locally do
        matches = patterns.map{ |pattern| ::Dir.glob(pattern, opts) }.flatten
      end
      if block_given?
        matches.each(&block)
      else
        matches
      end
    end

    # Glob files.
    #def glob(*args, &blk)
    #  Dir.glob(*args, &blk)
    #end

    # TODO: Ultimately merge #glob and #multiglob.
    def multiglob(*args, &blk)
      Dir.multiglob(*args, &blk)
    end

    def multiglob_r(*args, &blk)
      Dir.multiglob_r(*args, &blk)
    end

=begin
    # Match pattern. Like #glob but returns file objects.
    # TODO: There is no FileObject any more. Should there be?
    def match(*patterns, &block)
      opts = (::Integer===patterns.last ? patterns.pop : 0)
      patterns = localize(patterns)
      matches  = patterns.map{ |pattern| ::Dir.glob(pattern, opts) }.flatten
      matches  = matches.map{ |f| FileObject[f] }
      if block_given?
        matches.each(&block)
      else
        matches
      end
    end
=end

    # Join paths.
    # TODO: Should this return a new directory object? Or should it change directories?
    def /(path)
      #@_work += dir   # did not work, why?
      @_work = dir(localize(path))
      self
    end

    # Alias for #/.
    alias_method '+', '/'

    # TODO: Tie this into the System class.
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

    # -- File IO Shortcuts -----------------------------------------------

    # Read file.
    def read(path)
      File.read(localize(path))
    end

    # Write file.
    def write(path, text)
      $stderr.puts "write #{path}" if trace?
      File.open(localize(path), 'w'){ |f| f << text } unless noop?
    end

    # Append to file.
    def append(path, text)
      $stderr.puts "append #{path}" if trace?
      File.open(localize(path), 'a'){ |f| f << text } unless noop?
    end


    #############
    # FileTest  #
    #############

    #
    def size(path)        ; FileTest.size(localize(path))       ; end
    def size?(path)       ; FileTest.size?(localize(path))      ; end
    def directory?(path)  ; FileTest.directory?(localize(path)) ; end
    def symlink?(path)    ; FileTest.symlink?(localize(path))   ; end
    def readable?(path)   ; FileTest.readable?(localize(path))  ; end
    def chardev?(path)    ; FileTest.chardev?(localize(path))   ; end
    def exist?(path)      ; FileTest.exist?(localize(path))     ; end
    def exists?(path)     ; FileTest.exists?(localize(path))    ; end
    def zero?(path)       ; FileTest.zero?(localize(path))      ; end
    def pipe?(path)       ; FileTest.pipe?(localize(path))      ; end
    def file?(path)       ; FileTest.file?(localize(path))      ; end
    def sticky?(path)     ; FileTest.sticky?(localize(path))    ; end
    def blockdev?(path)   ; FileTest.blockdev?(localize(path))  ; end
    def grpowned?(path)   ; FileTest.grpowned?(localize(path))  ; end
    def setgid?(path)     ; FileTest.setgid?(localize(path))    ; end
    def setuid?(path)     ; FileTest.setuid?(localize(path))    ; end
    def socket?(path)     ; FileTest.socket?(localize(path))    ; end
    def owned?(path)      ; FileTest.owned?(localize(path))     ; end
    def writable?(path)   ; FileTest.writable?(localize(path))  ; end
    def executable?(path) ; FileTest.executable?(localize(path))  ; end

    def safe?(path)       ; FileTest.safe?(localize(path)) ; end

    def relative?(path)   ; FileTest.relative?(path)       ; end
    def absolute?(path)   ; FileTest.absolute?(path)       ; end

    def writable_real?(path)   ; FileTest.writable_real?(localize(path))   ; end
    def executable_real?(path) ; FileTest.executable_real?(localize(path)) ; end
    def readable_real?(path)   ; FileTest.readable_real?(localize(path))   ; end

    def identical?(path, other)
      FileTest.identical?(localize(path), localize(other))
    end
    alias_method :compare_file, :identical?

    # Assert that a path exists.
    #def exists?(path)
    #  paths = Dir.glob(path)
    #  paths.not_empty?
    #end
    #alias_method :exist?, :exists? #; module_function :exist?
    #alias_method :path?,  :exists? #; module_function :path?

    # Is a given path a regular file? If +path+ is a glob
    # then checks to see if all matches are regular files.
    #def file?(path)
    #  paths = Dir.glob(path)
    #  paths.not_empty? && paths.all?{ |f| FileTest.file?(f) }
    #end

    # Is a given path a directory? If +path+ is a glob
    # checks to see if all matches are directories.
    #def dir?(path)
    #  paths = Dir.glob(path)
    #  paths.not_empty? && paths.all?{ |f| FileTest.directory?(f) }
    #end
    #alias_method :directory?, :dir? #; module_function :directory?


    #############
    # FileUtils #
    #############

    # Low-level Methods Omitted
    # -------------------------
    # getwd           -> pwd
    # compare_file    -> cmp
    # remove_file     -> rm
    # copy_file       -> cp
    # remove_dir      -> rmdir
    # safe_unlink     -> rm_f
    # makedirs        -> mkdir_p
    # rmtree          -> rm_rf
    # copy_stream
    # remove_entry
    # copy_entry
    # remove_entry_secure
    # compare_stream

    # Present working directory.
    def pwd
      work.to_s
    end

    # Same as #identical?
    def cmp(a,b)
      fileutils.compare_file(a,b)
    end

    #
    def mkdir(dir, options={})
      dir = localize(dir)
      fileutils.mkdir(dir, options)
    end

    def mkdir_p(dir, options={})
      dir = localize(dir)
      unless File.directory?(dir)
        fileutils.mkdir_p(dir, options)
      end
    end
    alias_method :mkpath, :mkdir_p

    def rmdir(dir, options={})
      dir = localize(dir)
      fileutils.rmdir(dir, options)
    end

    # ln(list, destdir, options={})
    def ln(old, new, options={})
      old = localize(old)
      new = localize(new)
      fileutils.ln(old, new, options)
    end
    alias_method :link, :ln

    # ln_s(list, destdir, options={})
    def ln_s(old, new, options={})
      old = localize(old)
      new = localize(new)
      fileutils.ln_s(old, new, options)
    end
    alias_method :symlink, :ln_s

    def ln_sf(old, new, options={})
      old = localize(old)
      new = localize(new)
      fileutils.ln_sf(old, new, options)
    end

    # cp(list, dir, options={})
    def cp(src, dest, options={})
      src  = localize(src)
      dest = localize(dest)
      fileutils.cp(src, dest, options)
    end
    alias_method :copy, :cp

    # cp_r(list, dir, options={})
    def cp_r(src, dest, options={})
      src  = localize(src)
      dest = localize(dest)
      fileutils.cp_r(src, dest, options)
    end

    # mv(list, dir, options={})
    def mv(src, dest, options={})
      src  = localize(src)
      dest = localize(dest)
      fileutils.mv(src, dest, options)
    end
    alias_method :move, :mv

    def rm(list, options={})
      list = localize(list)
      fileutils.rm(list, options)
    end
    alias_method :remove, :rm

    def rm_r(list, options={})
      list = localize(list)
      fileutils.rm_r(list, options)
    end

    def rm_f(list, options={})
      list = localize(list)
      fileutils.rm_f(list, options)
    end

    def rm_rf(list, options={})
      list = localize(list)
      fileutils.rm_rf(list, options)
    end

    def install(src, dest, mode, options={})
      src  = localize(src)
      dest = localize(dest)
      fileutils.install(src, dest, mode, options)
    end

    def chmod(mode, list, options={})
      list = localize(list)
      fileutils.chmod(mode, list, options)
    end

    def chmod_r(mode, list, options={})
      list = localize(list)
      fileutils.chmod_r(mode, list, options)
    end
    #alias_method :chmod_R, :chmod_r

    def chown(user, group, list, options={})
      list = localize(list)
      fileutils.chown(user, group, list, options)
    end

    def chown_r(user, group, list, options={})
      list = localize(list)
      fileutils.chown_r(user, group, list, options)
    end
    #alias_method :chown_R, :chown_r

    def touch(list, options={})
      list = localize(list)
      fileutils.touch(list, options)
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

    # An intergrated glob like method that takes a set of include globs,
    # exclude globs and ignore globs to produce a collection of paths.
    #
    # Ignore_globs differ from exclude_globs in that they match by
    # the basename of the path rather than the whole pathname.
    #
    def amass(include_globs, exclude_globs=[], ignore_globs=[])
      locally do
        fileutils.amass(include_globs, exclude_globs, ignore_globs)
      end
    end

    #
    def outofdate?(path, *sources)
      #fileutils.outofdate?(localize(path), localize(sources))  # DIDN'T WORK, why?
      locally do
        fileutils.outofdate?(path, sources.flatten)
      end
    end

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

    #
    def uptodate?(path, *sources)
      locally do
        fileutils.uptodate?(path, sources.flatten)
      end
    end

    #
    #def uptodate?(new, old_list, options=nil)
    #  new = localize(new)
    #  old = localize(old_list)
    #  fileutils.uptodate?(new, old, options)
    #end

=begin
    # TODO: Deprecate these?

    # Assert that a path exists.
    def exists!(*paths)
      abort "path not found #{path}" unless paths.any?{|path| exists?(path)}
    end
    alias_method :exist!, :exists! #; module_function :exist!
    alias_method :path!,  :exists! #; module_function :path!

    # Assert that a given path is a file.
    def file!(*paths)
      abort "file not found #{path}" unless paths.any?{|path| file?(path)}
    end

    # Assert that a given path is a directory.
    def dir!(*paths)
      paths.each do |path|
        abort "Directory not found: '#{path}'." unless  dir?(path)
      end
    end
    alias_method :directory!, :dir! #; module_function :directory!
=end

  #private ?

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

    # Returns FileUtils module based on mode.
    def fileutils
      if dryrun?
        ::FileUtils::DryRun
      elsif noop?
        ::FileUtils::Noop
      elsif trace?
        ::FileUtils::Verbose
      else
        ::FileUtils
      end
    end

    # This may be used by script commands to allow for per command
    # noop and trace options. Global options have precedence.
    def util_options(options)
      noop  = noop?  || options[:noop]  || options[:dryrun]
      trace = trace? || options[:trace] || options[:dryrun]
      return noop, trace
    end

  public#class

    def self.[](path)
      new(path)
    end

  end

end

