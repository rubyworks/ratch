require 'pathname'
require 'fileutils'
require 'ratch/core_ext'
require 'ratch/batch'

module Ratch

  # Raised when a path that has to exist doesn't.
  class FileNotFound < StandardError
  end

  # = Shell Prompt class
  #
  # A Shell object is a file system shell in code: it stands at a
  # directory, and paths given to its methods are taken from there, much
  # as they are at a shell prompt.
  #
  #   shell = Ratch::Shell.new('project')
  #
  #   shell.file?('README.md')
  #   shell.mkdir_p('tmp/cache')
  #   shell.cp('README.md', 'tmp')
  #   shell.sh('git status')
  #
  # The process's own working directory is left alone, so shells at
  # different directories can be used side by side, and from different
  # threads.
  #
  # A shell can be put in a mode in which it only pretends:
  #
  #   shell = Ratch::Shell.new('project', :dryrun=>true)
  #   shell.rm_r('tmp')    # prints "rm -r tmp" and removes nothing
  #
  # NOTE: We use the term *trace* in place of *verbose* for the option
  # that reports each step. Ruby's FileUtils calls it *verbose*, but that
  # word is often wanted for a command's own purposes.
  #
  class Shell

    #
    def self.[](*path)
      new(*path)
    end

    # New Shell object. The path can be given in parts. Without one, the
    # shell stands at the present working directory.
    #
    #   Shell.new(:noop=>true)
    #   Shell.new('..', :quiet=>true)
    #
    # Options:
    #
    #   :quiet   print nothing; commands run with #sh have their output dropped
    #   :noop    change nothing on disk and run no commands (also :nowrite)
    #   :trace   report each step (also :verbose)
    #   :dryrun  both :noop and :trace
    #
    def initialize(*path)
      opts = (Hash === path.last ? path.pop : {})
      opts = opts.each_with_object({}){ |(k, v), h| h[k.to_sym] = v }

      set_options(opts)

      path = path.empty? ? Dir.pwd : File.join(*path.map{ |part| part.to_s })

      raise FileNotFound, "#{path}" unless ::File.directory?(path)

      @_work = Pathname.new(path).expand_path
    end

  private

    #
    def set_options(opts)
      @_quiet   = !!(opts[:quiet]   || opts[:silent])
      @_nowrite = !!(opts[:nowrite] || opts[:noop]    || opts[:dryrun])
      @_trace   = !!(opts[:trace]   || opts[:verbose] || opts[:dryrun])
    end

    # The options a new shell needs to be in the same mode as this one.
    def mode_options
      {:quiet=>quiet?, :noop=>noop?, :trace=>trace?}
    end

  public

    def quiet?   ; @_quiet   ; end
    def trace?   ; @_trace   ; end
    def nowrite? ; @_nowrite ; end

    def dryrun?  ; nowrite? && trace? ; end

    alias_method :verbose?, :trace?
    alias_method :noop?, :nowrite?

    # String representation is work directory path.
    def to_s ; work.to_s ; end

    #
    def inspect
      "#<#{self.class} #{work}>"
    end

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

    #
    def hash
      [self.class, work, noop?].hash
    end

    # Provides convenient starting points in the file system.
    #
    #   root   #=> #<Pathname:/>
    #   home   #=> #<Pathname:/home/jimmy>
    #   work   #=> #<Pathname:/home/jimmy/Documents>
    #
    # Each takes path parts to add, and the result must be a directory.

    # Root location.
    def root(*parts)
      dir(File.join('/', *parts.map{ |part| part.to_s }))
    end

    # Current home path.
    def home(*parts)
      dir(File.join(File.expand_path('~'), *parts.map{ |part| part.to_s }))
    end

    # Current working path.
    def work(*parts)
      return @_work if parts.empty?
      dir(File.join(*parts.map{ |part| part.to_s }))
    end

    # Present working directory, as a String.
    def pwd
      work.to_s
    end

    # The directory above the working path.
    def parent
      work.parent
    end

    # Returns a Batch of file +patterns+.
    def batch(*patterns)
      Batch.new(work, *patterns, mode_options)
    end

    # Returns a Batch of file +patterns+, without any exclusions.
    def batch_all(*patterns)
      Batch.all(work, *patterns, mode_options)
    end

    # A Pathname for a path, which need not exist.
    def path(path)
      Pathname.new(localize(path))
    end
    alias_method :pathname, :path

    # A Pathname for a file, which must exist.
    def file(path)
      path = localize(path)
      raise FileNotFound, path unless File.file?(path)
      Pathname.new(path)
    end

    # A Pathname for a directory, which must exist.
    def dir(path)
      path = localize(path)
      raise FileNotFound, path unless File.directory?(path)
      Pathname.new(path)
    end

    # Lists all entries, as Dir.entries does, but as Pathnames.
    def entries
      work.entries
    end

    # Lists directory entries.
    def directory_entries
      entries.select{ |d| (work + d).directory? }
    end

    #
    alias_method :dir_entries, :directory_entries

    # Lists file entries.
    def file_entries
      entries.select{ |f| (work + f).file? }
    end

    # Like #entries but omits the '.' and '..' paths.
    def pathnames
      work.children(false)
    end

    # Returns list of directories.
    def directories
      pathnames.select{ |d| (work + d).directory? }
    end
    alias_method :dirs, :directories
    alias_method :folders, :directories

    # Returns list of files.
    def files
      pathnames.select{ |f| (work + f).file? }
    end

    # A new shell at a directory under this one, in the same mode.
    #
    #   lib = shell / 'lib'
    #
    def /(path)
      self.class.new(dir(path), mode_options)
    end

    # Alias for #/.
    alias_method :+, :/

    # Run a command from the working directory, as Kernel#system does,
    # whatever the mode.
    def system(*cmd)
      opts = (Hash === cmd.last ? cmd.pop.dup : {})
      opts[:chdir] ||= work.to_s
      ::Kernel.system(*cmd, **opts)
    end

    # Shell runner. Runs a command from the working directory and returns
    # true if it succeeded. In trace mode the command is printed first; in
    # noop mode it is not run; in quiet mode its output is dropped.
    #
    #   shell.sh 'make install'
    #   shell.sh 'git', 'commit', '-m', message
    #
    def sh(*cmd)
      $stderr.puts cmd.join(' ') if trace?
      return true if noop?
      if quiet?
        system(*cmd, :out=>File::NULL, :err=>File::NULL)
      else
        system(*cmd)
      end
    end

    # Change working directory.
    #
    # With a block, the shell stands at +path+ for the length of the block
    # and then returns to where it was. The process's working directory is
    # changed too for that time, so that code in the block which doesn't
    # go through the shell sees the same directory. Ruby allows only one
    # such block at a time across threads.
    #
    def cd(path, &block)
      if block
        work_old = @_work
        begin
          @_work = dir(path)
          Dir.chdir(@_work.to_s){ block.call(self) }
        ensure
          @_work = work_old
        end
      else
        @_work = dir(path)
      end
    end

    #
    alias_method :chdir, :cd

    # -- FileTest --

    # File tests, which take one path.
    FILE_TESTS = %w{
      size size? directory? symlink? readable? chardev? exist?
      zero? pipe? file? sticky? blockdev? grpowned? setgid? setuid?
      socket? owned? writable? executable? readable_real?
      writable_real? executable_real? world_readable? world_writable?
    }

    FILE_TESTS.each do |name|
      module_eval <<-EOS, __FILE__, __LINE__ + 1
        def #{name}(path)
          ::FileTest.#{name}(localize(path))
        end
      EOS
    end

    alias_method :dir?, :directory?

    # Ruby dropped +exists?+ in 3.2; it is kept here.
    alias_method :exists?, :exist?

    # Is the path safe from the meddling of others?
    def safe?(path)
      ::FileTest.safe?(localize(path))
    end

    def relative?(path); ::FileTest.relative?(path.to_s); end
    def absolute?(path); ::FileTest.absolute?(path.to_s); end

    # Are the two paths the same file?
    def identical?(path, other)
      ::FileTest.identical?(localize(path), localize(other))
    end

    # Do the two files have the same content?
    def cmp(path, other)
      ::FileUtils.compare_file(localize(path), localize(other))
    end
    alias_method :compare_file, :cmp

    # -- FileUtils --
    #
    # Each takes the options of its FileUtils namesake. The shell's mode
    # sets :noop and :verbose.
    #
    # These low-level FileUtils methods have been omitted.
    #
    # * getwd           -> pwd
    # * remove_file     -> rm
    # * copy_file       -> cp
    # * remove_dir      -> rmdir
    # * safe_unlink     -> rm_f
    # * copy_stream
    # * remove_entry
    # * copy_entry
    # * remove_entry_secure
    # * compare_stream

    # Methods taking a path or a list of paths.
    %w{mkdir mkdir_p rmdir rm rm_r rm_f rm_rf touch}.each do |name|
      module_eval <<-EOS, __FILE__, __LINE__ + 1
        def #{name}(list, options={})
          fu(:#{name}, options, list){ |opts| ::FileUtils.#{name}(localize(list), **opts) }
        end
      EOS
    end

    alias_method :mkpath, :mkdir_p
    alias_method :makedirs, :mkdir_p
    alias_method :remove, :rm
    alias_method :rmtree, :rm_rf

    # Methods taking a source, or a list of them, and a destination.
    %w{ln ln_s ln_sf cp cp_r mv}.each do |name|
      module_eval <<-EOS, __FILE__, __LINE__ + 1
        def #{name}(src, dest, options={})
          fu(:#{name}, options, src, dest){ |opts| ::FileUtils.#{name}(localize(src), localize(dest), **opts) }
        end
      EOS
    end

    alias_method :link, :ln
    alias_method :symlink, :ln_s
    alias_method :copy, :cp
    alias_method :move, :mv

    # Copy +src+ to +dest+, setting its mode. The mode can be given as the
    # third argument or as the :mode option.
    def install(src, dest, mode=nil, options={})
      options, mode = mode, nil if Hash === mode
      options = options.merge(:mode=>mode) if mode
      fu(:install, options, src, dest){ |opts| ::FileUtils.install(localize(src), localize(dest), **opts) }
    end

    #
    def chmod(mode, list, options={})
      fu(:chmod, options, (Integer === mode ? '%o' % mode : mode), list){ |opts| ::FileUtils.chmod(mode, localize(list), **opts) }
    end

    #
    def chmod_R(mode, list, options={})
      fu(:chmod_R, options, (Integer === mode ? '%o' % mode : mode), list){ |opts| ::FileUtils.chmod_R(mode, localize(list), **opts) }
    end
    alias_method :chmod_r, :chmod_R

    #
    def chown(user, group, list, options={})
      fu(:chown, options, [user, group].compact.join(':'), list){ |opts| ::FileUtils.chown(user, group, localize(list), **opts) }
    end

    #
    def chown_R(user, group, list, options={})
      fu(:chown_R, options, [user, group].compact.join(':'), list){ |opts| ::FileUtils.chown_R(user, group, localize(list), **opts) }
    end
    alias_method :chown_r, :chown_R

    # Is +path+ newer than all of +sources+?
    def uptodate?(path, *sources)
      ::FileUtils.uptodate?(localize(path), localize(sources.flatten))
    end

    # Does +path+ need updating, going by +sources+, which can be globs?
    # True if it doesn't exist or is older than any of them.
    def outofdate?(path, *sources)
      path = localize(path)
      return true unless File.exist?(path)
      mtimes = glob(*sources.flatten).map{ |file| File.mtime(localize(file)) }
      return true if mtimes.empty?
      File.mtime(path) < mtimes.max
    end

    # Hard link +files+, which are relative to the working directory, into
    # a staging directory, making it afresh.
    def stage(stage_dir, files, options={})
      rm_r(stage_dir, options) if directory?(stage_dir)
      mkdir_p(stage_dir, options)
      [files].flatten.each do |file|
        dest = File.join(stage_dir.to_s, file.to_s)
        if directory?(file)
          mkdir_p(dest, options)
        else
          mkdir_p(File.dirname(dest), options) unless directory?(File.dirname(dest))
          ln(file, dest, options)
        end
      end
      path(stage_dir)
    end

    # A glob-like method that takes a set of include globs, exclude globs
    # and ignore globs and gives the paths that are left. A directory
    # stands for everything in it.
    #
    # The ignore globs differ from the exclude globs in that they are
    # matched against the base name of a path, not the whole of it.
    #
    def amass(include_globs, exclude_globs=[], ignore_globs=[])
      expand = lambda do |globs|
        [globs].flatten.map{ |g| directory?(g) ? [g, File.join(g.to_s, '**/*')] : g }.flatten
      end
      files = glob(*expand.call(include_globs)) - glob(*expand.call(exclude_globs))
      files = files.uniq
      files.reject do |f|
        [ignore_globs].flatten.any?{ |x| File.fnmatch?(x, File.basename(f)) }
      end
    end

    # -- File --

    # Get creation timestamp.
    def ctime(path)
      File.ctime(localize(path))
    end

    # Get, or with a time set, the last access timestamp.
    def atime(path, time=nil, options={})
      options, time = time, nil if Hash === time
      return File.atime(localize(path)) unless time
      utime(time, File.mtime(localize(path)), path, options)
    end

    # Get, or with a time set, the last modification timestamp.
    def mtime(path, time=nil, options={})
      options, time = time, nil if Hash === time
      return File.mtime(localize(path)) unless time
      utime(File.atime(localize(path)), time, path, options)
    end

    # Set the access and modification timestamps of files.
    def utime(atime, mtime, *files)
      opts = fu_options(Hash === files.last ? files.pop : {})
      $stderr.puts "utime #{atime} #{mtime} #{files.join(' ')}" if opts[:verbose]
      File.utime(atime, mtime, *localize(files.flatten)) unless opts[:noop]
    end

    # Read file.
    def read(path)
      File.read(localize(path))
    end

    # Write file.
    def write(path, text, options={})
      opts = fu_options(options)
      $stderr.puts "write #{path}" if opts[:verbose]
      File.open(localize(path), 'w'){ |f| f << text } unless opts[:noop]
    end

    # Append to file.
    def append(path, text, options={})
      opts = fu_options(options)
      $stderr.puts "append #{path}" if opts[:verbose]
      File.open(localize(path), 'a'){ |f| f << text } unless opts[:noop]
    end

    # -- Dir --

    # Glob patterns. Returns the matches as strings, relative to the
    # working directory unless a pattern is absolute. A trailing Integer
    # is taken as File::FNM flags.
    def glob(*patterns, &block)
      flags = (::Integer === patterns.last ? patterns.pop : 0)
      matches = []
      patterns.flatten.each do |pattern|
        pattern = pattern.to_s
        if absolute?(pattern)
          matches.concat(Dir.glob(pattern, flags))
        else
          matches.concat(Dir.glob(pattern, flags, :base=>work.to_s))
        end
      end
      if block
        matches.each(&block)
      else
        matches
      end
    end

  private

    # Returns a path local to the current working path. An absolute path
    # is left as it is, and so is nil. Given a list, localizes each.
    def localize(local_path)
      case local_path
      when nil
        nil
      when Array
        local_path.map{ |lp| localize(lp) }
      else
        local_path = local_path.to_s
        return local_path if absolute?(local_path)
        File.expand_path(File.join(work.to_s, local_path))
      end
    end

    # Run a block with the process's working directory set to the shell's.
    # Nothing in Shell itself needs this; it is for extensions that call
    # code which only knows the process's directory.
    def locally(&block)
      if work.to_s == Dir.pwd
        block.call
      else
        Dir.chdir(work.to_s, &block)
      end
    end

    # TODO: Should naming policy be in a utility extension module?

    #
    def naming_policy(*policies)
      if policies.empty?
        @naming_policy ||= ['down', 'ext']
      else
        @naming_policy = policies
      end
    end

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

    # How each file operation reads in a trace.
    FU_COMMANDS = {
      :mkdir_p=>'mkdir -p', :rm_r=>'rm -r', :rm_f=>'rm -f', :rm_rf=>'rm -rf',
      :ln_s=>'ln -s', :ln_sf=>'ln -sf', :cp_r=>'cp -r',
      :chmod_R=>'chmod -R', :chown_R=>'chown -R'
    }

    # Carry out a file operation in the shell's mode: report it if
    # tracing, with the paths as they were given, and yield the options
    # for FileUtils unless this is a noop.
    def fu(name, options, *args)
      opts    = fu_options(options)
      noop    = opts.delete(:noop)
      verbose = opts.delete(:verbose)
      if verbose
        $stderr.puts [FU_COMMANDS[name] || name.to_s, *args.flatten].join(' ')
      end
      yield(opts) unless noop
    end

    # The options given for one command, with :noop and :verbose turned
    # on if the shell's mode says so. The shell's own names for them
    # (:trace, :nowrite, :dryrun) are accepted per command as well.
    def fu_options(options)
      opts = {}
      (options || {}).each{ |k, v| opts[k.to_sym] = v }
      given   = [:dryrun, :nowrite, :noop, :trace, :verbose].select{ |k| opts.delete(k) }
      dryrun  = given.include?(:dryrun)
      opts[:noop]    = true if noop?    || dryrun || given.include?(:nowrite) || given.include?(:noop)
      opts[:verbose] = true if trace? || dryrun || given.include?(:trace)   || given.include?(:verbose)
      opts
    end

    # This may be used by utility extensions to allow for per command
    # noop and trace options. The shell's mode has precedence. Returns
    # the two as a pair.
    def util_options(options)
      opts = fu_options(options)
      return !!opts[:noop], !!opts[:verbose]
    end

  end

end
