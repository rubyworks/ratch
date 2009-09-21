require 'optparse'

module Ratch

  #
  # TODO: switch to ArgVector so it can be used by anyone without preprocessing?
  #
  class CLI
    attr :usage
    attr :options

    def initialize
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

    def arguments
      @argv
    end

    def method_missing(s, *a, &b)
      @options[s.to_sym]
    end
  end

end
