#require 'optparse'
require 'facets/argvector'

module Ratch

  #
  class CLI

    # Commandline arguments
    attr :arguments

    # Commandline named parameters.
    attr :parameters

    #
    def initialize(argv=nil)
      argv = ArgVector.new(argv || ARGV)

      @arguments, @parameters = *argv.parameters
    end

    #
    def noop?
      @parameters['noop'] || @parameters['n']
    end

    #
    def verbose?
      @parameters['verbose'] || @parameters['v']
    end

    #
    def dryrun?
      @parameters['dryrun'] or (noop? and verbose?)
    end

    #
    def trace?
      @parameters['trace'] or (debug? and verbose?)
    end

    #
    def method_missing(s, *a, &b)
      s = s.to_s.chomp('?')
      @parameters[s]
    end

  end

end

=begin
    def
      @options = {}
      @usage   = OptionParser.new

      @usage.on('--debug', "debug mode") do
        @options[:debug] = true
      end

      @usage.on('--trace', "trace execution (same as verbose and debug") do
        #@options[:trace] = true
        @options[:debug] = true
        @options[:verbose] = true
      end

      @usage.on('--noop', '-n', "no disk writes") do
        @options[:noop] = true
      end

      @usage.on('--verbose', "extra verbose output") do
        @options[:verbose] = true
      end

      @usage.on('--dryrun', '-d', "both noop and verbose") do
        @options[:noop] = true
        @options[:verbose] = true
      end

      @usage.on('--quiet', '-q', "run silently") do
        @options[:quiet] = true
      end

      @usage.on('--force', "force operations") do
        @options[:force] = true
      end

      @usage.on_tail('--help', "display help") do
        puts @usage
        exit
      end
    end

    def parse!(argv=nil)
      @argv ||= ARGV.dup
      @usage.parse!(@argv)
    end
=end

