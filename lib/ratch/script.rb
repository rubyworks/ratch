require 'yaml'
require 'rbconfig'  # replace with facets/rbsystem?

require 'facets/platform'
#require 'facets/openhash'
#require 'facets/argvector'

require 'ratch/core_ext'

require 'ratch/shell'
require 'ratch/io'
require 'ratch/cli'
#require 'ratch/task'  # TODO: really?

module Ratch

  # = Ratch Script
  #
  # The DSL class is the heart of Ratch, it provides all the convenece methods
  # that make Ratch so convenient for writing Ruby-based batch script.
  #
  # The Ratch Script class is used to run stand-alone ratch scripts.
  # Yep, this is actaully a class named exactly for what it is.
  # How rare.
  #
  class Script < Module
    #include Taskable
    #include Taskable::Dsl

    # FIXME: Use facets/plugin_manager
    #def load_plugins
    #  $LOAD_PATH.each do |path|
    #    plugins = Dir[File.join(path, 'ratchets/*.rb')]
    #    plugins.each{ |file|  require(file) }
    #  end
    #end

    #
    def initialize(options={})
      extend self

      initialize_defaults

      options.each do |k, v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end

      @cli = ioc[:cli] || CLI.new

      @io  = ioc[:io]  || IO.new(@cli)

      path = options[:path] || Dir.pwd

      @shell = Shell.new(path, :noop => @cli.noop?, :verbose => @cli.verbose?, :quiet => @cli.quiet?)
    end

    private

    # This can be used by subclasses.
    def initialize_defaults
    end

    # The #cli method provides delagated access to commandline
    # arguments and options via a Ratch::CLI interface.
    attr :cli

    # Delagate input/output routines to Ratch::IO object.
    attr :io

    # Delagate file operations to Shell.
    attr :shell

    def force?   ; cli.force?   ; end
    def debug?   ; cli.debug?   ; end
    def quiet?   ; cli.quiet?   ; end
    def noop?    ; cli.noop?    ; end
    def verbose? ; cli.verbose? ; end

    def trace?   ; cli.debug && cli.verbose? ; end
    def dryrun?  ; cli.noop? && cli.verbose? ; end

    # Current platform.
    def current_platform
      Platform.local.to_s
    end

    # Delegate to Shell.
    def method_missing(s, *a, &b)
      if @shell.respond_to?(s)
        @shell.__send__(s, *a, &b)
      else
        super
      end
    end

    # Load configuration data from a file.
    # Results are cached and and empty Hash is
    # returned if the file is not found.
    #
    # Since they are YAML files, they can optionally
    # end with '.yaml' or '.yml'.
    def configuration(file)
      @configuration ||= {}
      @configuration[file] ||= (
        begin
          configuration!(file)
        rescue LoadError
          Hash.new{ |h,k| h[k] = {} }
        end
      )
    end

    # Load configuration data from a file.
    # The "bang" version will raise an error
    # if file is not found. It also does not
    # cache the results.
    #
    # Since they are YAML files, they can optionally
    # end with '.yaml' or '.yml'.
    def configuration!(file)
      @configuration ||= {}
      patt = file + "{.yml,.yaml,}"
      path = Dir.glob(patt, File::FNM_CASEFOLD).find{ |f| File.file?(f) }
      if path
        # The || {} is in case the file is empty.
        data = YAML::load(File.open(path)) || {}
        @configuration[file] = data
      else
        raise LoadError, "Missing file -- #{path}"
      end
    end

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


    #
    def report(message)
      #puts message unless quiet?
      io.report(message)
    end

    # Internal status report.
    # Only output if dryrun or trace mode.
    def status(message)
      io.status(message)
    end

    # Convenient method to get simple console reply.
    def ask(question, answers=nil)
      io.ask(question, answers)
    end

    # Ask for a password. (FIXME: only for unix so far)
    def password(prompt=nil)
      io.password(prompt)
    end

  end

end


#    # Compress directory.
#    #
#    def compress(format, folder, file=nil, options={})
#      case format.to_s.downcase
#      when 'zip'
#        ziputils.zip(folder, file, options)
#      when 'tgz'
#        ziputils.tgz(folder, file, options)
#      when 'tbz', 'bzip'
#        ziputils.tar_bzip(folder, file, options)
#      else
#        raise ArguementError, "unsupported compression format -- #{format}"
#      end
#    end

    # Glob files.
    #def glob(*args, &blk)
    #  Dir.glob(*args, &blk)
    #end

    # Multiglob files.
    #def multiglob(*args, &blk)
    #  Dir.multiglob(*args, &blk)
    #end

    # Multiglob recursive.
    #def multiglob_r(*args, &blk)
    #  Dir.multiglob_r(*args, &blk)
    #end

=begin
    # Does a path need updating, based on given +sources+?
    # This compares mtimes of give paths. Returns false
    # if the path needs to be updated.
    #
    # TODO: Put this in FileTest instead?

    def out_of_date?(path, *sources)
      return true unless File.exist?(path)

      sources = sources.collect{ |source| Dir.glob(source) }.flatten
      mtimes  = sources.collect{ |file| File.mtime(file) }

      return true if mtimes.empty?  # TODO: This the way to go here?

      File.mtime(path) < mtimes.max
    end
=end


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

    #alias_method :pwd, :work

    # Bonus FileUtils features.
    #def cd(*a,&b)
    #  puts "cd #{a}" if dryrun? or trace?
    #  fileutils.chdir(*a,&b)
    #end

    # DEPRECATE!
    #alias_method :commandline, :cli

    # DEPRECATE!
    #alias_method :command, :cli

    #
    #def commandline
    #  #@commandline ||= ArgVector.new(ARGV)
    #  @commandline
    #end
