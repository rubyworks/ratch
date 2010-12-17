require 'yaml'
require 'rbconfig'
require 'plugin'    # rename to plugin_manager ?

require 'ratch/core_ext/all'
require 'ratch/cli'
require 'ratch/plugin'
require 'ratch/shell'

#require 'ratch/task'  # TODO: really?
#require 'ratch/log'
#require 'ratch/shell'

module Ratch

  # = Ratch Script
  #
  # The DSL class is the heart of Ratch, it provides all the methods
  # that make Ratch so convenient for writing Ruby-based batch script.
  #
  # The Ratch Script class is used to run stand-alone ratch scripts.
  # Yep, this is actaully a class named exactly for what it is.
  # How rare.
  #
  class Script < Module
    #include Taskable
    #include Taskable::Dsl

    # load script plugins
    ::Plugin.find('ratch/script/*') do |file|
      module_eval(File.read(file), file)  # require file
    end

    #
    def initialize(options={})
      extend self

      #@project = Gemdo::Project.new
      #options[:path] = @project.root

      #@_stdout = options[:stdout] || $stdout
      #@_stderr = options[:stderr] || $stderr
      #@_stdin  = options[:stdin]  || $stdin

      initialize_defaults

      #options.each do |k, v|
      #  send("#{k}=", v) if respond_to?("#{k}=")
      #end

      @script_delegates = []

      @cli = options[:cli]  || CLI.new

      path = options[:path] || Dir.pwd

      @shell = Shell.new(path, :noop=>@cli.noop?, :verbose=>@cli.verbose?, :quiet=>@cli.quiet?)

      use @shell
    end

  private

    # This can be used by subclasses.
    def initialize_defaults
    end

    # The #cli method provides delagated access to commandline
    # arguments and options via the Ratch::CLI interface.
    def cli
      @cli
    end

    # Delagate file operations to instance of Ratch::Shell.
    def shell
      @shell
    end

    def force?   ; cli.force?   ; end
    def debug?   ; cli.debug?   ; end
    def quiet?   ; cli.quiet?   ; end
    def noop?    ; cli.noop?    ; end
    def verbose? ; cli.verbose? ; end
    def trace?   ; cli.trace?   ; end
    def dryrun?  ; cli.dryrun?  ; end

    # Convenient method to get simple console reply.
    #def ask(question, answers=nil)
    #  stdout.print "#{question}"
    #  stdout.print " [#{answers}] " if answers
    #  stdout.flush
    #  until inp = stdin.gets ; sleep 1 ; end
    #  inp.strip
    #end

    # Ask for a password. (FIXME: only for unix so far)
    #def password(prompt=nil)
    #  prompt ||= "Enter Password: "
    #  inp = ''
    #  stdout << "#{prompt} "
    #  stdout.flush
    #  begin
    #    #system "stty -echo"
    #    #inp = gets.chomp
    #    until inp = $stdin.gets
    #      sleep 1
    #    end
    #  ensure
    #    #system "stty echo"
    #  end
    #  return inp.chomp
    #end

    # TODO: Until we have better support for getting input acorss platforms
    # we are using #ask only.
    def password(prompt=nil)
      prompt ||= "Enter Password: "
      ask(prompt)
    end

    #
    def print(str=nil)
      super(str.to_s) unless quiet?
    end

    #
    def puts(str=nil)
      super(str.to_s) unless quiet?
    end

    #
    def report(message)
      puts(message) unless quiet?
    end

    #
    def status(message)
      puts message unless quiet?
    end

    # Internal status report.
    # Only output if verbose mode.
    #
    def trace(message)
      puts message if verbose?
    end

    # Access a log by name.
    #def logfile(path)
    #  @logfile ||= {}
    #  @logfile[path.to_s] ||= (
    #    Log.new(project.log + name.to_s, :noop=>noop?, :verbose=>verbose?)
    #  )
    #end

    # to be deprecated
    #alias_method :log, :logfile

   #
    def use(object)
      @script_delegates << object
    end

    #
    def method_missing(s, *a, &b)
      @script_delegates.each do |delegate|
        if delegate.respond_to?(s)
          v = delegate.__send__(s, *a, &b)
          return v
        end
      end
      super(s, *a, &b)
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

=begin
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
=end

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
