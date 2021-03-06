require 'ratch/core_ext'
require 'ratch/shell'
#require 'ratch/plugin'

# CLI extension is required.
require 'ratch/utils/cli'

module Ratch

  # The Ratch Script class is used to run stand-alone Ratch scripts.
  # Yep, this is actaully a class named exactly for what it is.
  # How rare.
  #
  #--
  # Previous versions of this class subclassed Module and called `self extend`
  # in the +initialize+ method. Then used +method_missing+ to route to an
  # instance of Shell. The current design works the other way round.
  # Both approaches seem to work just as well, though perhaps one is more
  # robust than another? I have chosen this design simply b/c the shell
  # methods should dispatch a bit faster.
  #++
  class Script < Shell #< Module

    include CLI

    #
    def self.execute(script, *args)
      script = new(script, *args)
      script.execute!
    end

    #
    def initialize(file, *args)
      @_file = file.to_s

      #extend self

      super(*args)

      #@_stdout = options[:stdout] || $stdout
      #@_stderr = options[:stderr] || $stderr
      #@_stdin  = options[:stdin]  || $stdin
    end

    # Returns the file name of the script.
    def script_file
      @_file
    end

    # Be cautious about calling this in a script --an infinite loop could
    # easily ensue.
    def execute!
      old = $0
      begin
        $0 = script_file
        instance_eval(File.read(script_file), script_file, 1)
      ensure
        $0 = old
      end
    end

    alias_method :run!, :execute!

    #
    #def print(str=nil)
    #  super(str.to_s) unless quiet?
    #end

    #
    #def puts(str=nil)
    #  super(str.to_s) unless quiet?
    #end

    # TODO: Deprecate one of the three #report, #status, #trace.
    def report(message)
      #@_stdout.puts(message) unless quiet?
      puts(message) unless quiet?
    end

    #
    def status(message)
      #@_stdout.puts message unless quiet?
      puts message unless quiet?  # dryrun? or trace?
    end

    # Internal status report. Only output if in trace mode.
    #
    def trace(message)
      #@_stdout.puts message if trace?
      puts message if trace?
    end

    # Pass-thru to singleton class.
    def define_method(name, &block)
      (class << self; self; end).__send__(:define_method, &block)
    end

    ## If method is missing, try the singleton class. This allows the script
    ## to use methods like +define_method+.
    ##
    ## TODO: Perhaps it would be best to limit the selection of methods?
    #def method_missing(sym, *args, &blk)
    #  (class << self; self; end).__send__(sym, *args, &blk)
    #end

  end

end
