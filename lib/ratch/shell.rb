require 'thread'
require 'ratch/ruby/pathname'
require 'ratch/ruby/filetest'
require 'ratch/ruby/fileutils'
#require 'ratch/core_ext'
#require 'ratch/ziputils'
#require 'ratch/xdg'

require 'ratch/pathlist'

module Ratch

  # = Shell Prompt class
  #
  # Ratch Shell object provides a limited file system shell in code.
  # It is similar to having a shell prompt available to you in Ruby.
  #
  class Shell

    # require shell commands
    Dir[File.dirname(__FILE__) + '/shell/*.rb'].each do |file|
      require(file) #instance_eval(File.read(file))
    end

    # New Shell object.
    def initialize(*path_opts)
      opts = (Hash===path_opts.last ? path_opts.pop : {})
      path = path_opts

      @quiet   = opts[:quiet]
      @noop    = opts[:noop]
      @verbose = opts[:verbose]
      @debug   = opts[:debug]

      if path.empty?
        path = Dir.pwd
      else
        path = File.join(*path)
      end

      raise FileNotFound, "#{path}" unless ::File.exist?(path)
      raise FileNotFound, "#{path}" unless ::File.directory?(path)

      @work  = dir(path)
    end

    #
    def mutex
      @mutex ||= Mutex.new
    end

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

    def quiet?   ; @quiet   ; end
    def debug?   ; @debug   ; end

    def noop?    ; @noop    ; end
    def verbose? ; @verbose ; end

    def dryrun?  ; @noop  && @verbose ; end
    def trace?   ; @debug && @verbose ; end

    # String representation is work directory path.
    def to_s ; work.to_s ; end

    #
    def ==(other)
      return false unless self.class===other
      return true  if     @work == other.work
      false
    end

    # Present working directory.
    #attr :work

  # TODO: Should these take the *args?

    # Root location.
    def root(*args)
      dir('/', *args)
    end

    # Current home path.
    def home(*args)
      dir('~', *args)
    end

    # Current working path.
    def work(*args)
      return @work if args.empty?
      return dir(@work, *args)
    end

    # Alias for #work.
    alias_method :pwd, :work

    # Return a new prompt with the same location.
    # NOTE: Use #dup or #clone ?
    #def new ; Shell.new(work) ; end

    def parent
      dir('..')
    end

    #
    def [](name)
      #FileObject[localize(name)]
      #Pathname.new(localize(path))
      Pathlist.new(localize(path))
    end

    # TODO: should #file and this be the same?
    def file(path)
      #FileObject[name]
      raise unless File.file?(path)
      Pathname.new(localize(path))
    end

    #def doc(name)
    #  Document.new(name)
    #end

    def dir(path)
      #Directory.new(name)
      raise unless File.directory?(path)
      Pathname.new(localize(path))
    end

    def path(path)
      Pathname.new(localize(path))
    end
    alias_method :pathname, :path

    # Lists all entries.
    def entries
      work.entries
    end
    alias_method :ls, :entries

    # Lists directory entries.
    def directory_entries
      work.entries.select{ |d| d.directory? }
    end

    # Lists directory entries.
    def file_entries
      work.entries.select{ |f| f.file? }
    end

    # Returns list of files objects.
    #def files ; work.files ; end

    # Returns list of directories.
    #def documents ; work.documents ; end

    # Returns list of documents.
    def directories ; work.directories ; end

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

    # TODO: Ultimately merge #glob and #multiglob.
    def multiglob(*a)
      Dir.multiglob(*a)
    end

    def multiglob_r(*a)
      Dir.multiglob_r(*a)
    end

    # Match pattern. Like #glob but returns file objects.
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

    # Join paths.
    # TODO: Should this return a new directory object? Or should it change directories?
    def /(path)
      #@work += dir   # did not work, why?
      @work = dir(localize(path))
      self
    end

    # Alias for #/.
    alias_method '+', '/'

    #
    def system(cmd)
      locally do
        super(cmd)
      end
    end

    # Shell runner.
    def sh(cmd)
      #puts "--> system call: #{cmd}" if verbose?
      puts cmd if verbose?
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
        work_old = @work
        begin
          @work = dir(localize(path))
          locally(&block)
          #mutex.synchronize do
          #  Dir.chdir(@work){ block.call }
          #end
        ensure
          @work = work_old
        end
      else
        @work = dir(localize(path))
      end
    end

    alias_method :chdir, :cd

    # -- File IO Shortcuts -----------------------------------------------

    # Read file.
    def read(path)
      File.read(localize(path))
    end

    # Write file.
    def write(path, text)
      puts "write #{path}" if verbose?
      File.open(localize(path), 'w'){ |f| f << text } unless noop?
    end

    # Append to file.
    def append(path, text)
      puts "append #{path}" if verbose?
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
  #############
  # ZipUtils  #
  #############

  # Compress directory to file. Format is determined
  # by file extension.
  #def compress(folder, file, options={})
  #  #folder = localize(file)
  #  #file   = localize(file)
  #  locally do
  #    doc(ziputils.compress(folder, file, options))
  #  end
  #end

  #
  def gzip(file, tofile=nil, options={})
    #file   = localize(file)
    #tofile = localize(tofile) if tofile
    locally do
      file(ziputils.gzip(file, tofile, options))
    end
  end

  #
  def bzip(file, tofile=nil, options={})
    #file   = localize(file)
    #tofile = localize(tofile) if tofile
    locally do
      doc(ziputils.bzip(file, tofile, options))
    end
  end

  # Create a zip file of a directory.
  def zip(folder, file=nil, options={})
    #folder = localize(folder)
    #file   = localize(file)
    locally do
      doc(ziputils.zip(folder, file, options))
    end
  end

  #
  def tar(folder, file=nil, options={})
    #folder = localize(folder)
    #file   = localize(file)
    locally do
      doc(ziputils.tar_gzip(folder, file, options))
    end
  end

  # Create a tgz file of a directory.
  def tar_gzip(folder, file=nil, options={})
    #folder = localize(folder)
    #file   = localize(file)
    locally do
      doc(ziputils.tar_gzip(folder, file, options))
    end
  end
  alias_method :tgz, :tar_gzip

  # Create a tar.bz2 file of a directory.
  def tar_bzip2(folder, file=nil, options={})
    #folder = localize(folder)
    #file   = localize(file)
    locally do
      doc(ziputils.tar_bzip2(folder, file, options))
    end
  end

  def ungzip(file, options)
    #file   = localize(file)
    locally do
      ziputils.ungzip(file, options)
    end
  end

  def unbzip2(file, options)
    #file   = localize(file)
    locally do
      ziputils.unbzip2(file, options)
    end
  end

  def unzip(file, options)
    #file   = localize(file)
    locally do
      ziputils.unzip(file, options)
    end
  end

  def untar(file, options)
    #file   = localize(file)
    locally do
      ziputils.untar(file, options)
    end
  end

  def untar_gzip(file, options)
    #file   = localize(file)
    locally do
      ziputils.untar_gzip(file, options)
    end
  end

  def untar_bzip2(file, options)
    #file   = localize(file)
    locally do
      ziputils.untar_bzip2(file, options)
    end
  end
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
      end
    end

    #
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

  private

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

=begin
    # Returns ZipUtils module based on mode.
    def ziputils
      if dryrun?
        ::ZipUtils::DryRun
      elsif noop?
        ::ZipUtils::Noop
      elsif verbose?
        ::ZipUtils::Verbose
      else
        ::ZipUtils
      end
    end
=end

    # This may be used by script commands to allow for per command
    # noop and verbose options. Global options have precedence.
    def util_options(options)
      noop    = noop?    || options[:noop]    || options[:dryrun]
      verbose = verbose? || options[:verbose] || options[:dryrun]
      return noop, verbose
    end

  public#class

    def self.[](path)
      new(path)
    end

  end

end


# Could the prompt act as a delegate to file objects?
# If we did this then the file prompt could actually "cd" into a file.
#
=begin :nodoc:
  def initialize(path)
    @path = path = ::File.join(*path)

    raise FileNotFound unless ::File.exist?(path)

    if ::File.blockdev?(path) or chardev?(path)
      @delegate = Device.new(path)
    elsif ::File.link?(path)
      @delegate = Link.new(path)
    elsif ::File.directory?(path)
      @delegate = Directory.new(path)
    else
      @delegate = Document.new(path)
    end
  end

  def delete
    @delegate.delete
    @delegate = nil
  end
=end
#++

