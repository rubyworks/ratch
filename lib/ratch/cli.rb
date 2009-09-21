require 'optparse'

module Ratch

  class CLI
    attr :usage
    attr :options

    def initialize
      @options = {}
      @usage   = OptionParser.new

      @usage.on('--trace', "trace execution") do
        @options[:trace] = true
      end

      @usage.on('--debug', "debug mode") do
        @options[:debug] = true
      end

      @usage.on('--pretend', '-p', "no disk writes") do
        @options[:pretend] = true
      end

      @usage.on('--quiet', '-q', "run silently") do
        @options[:quiet] = true
      end

      @usage.on('--verbose', "extra output") do
        @options[:verbose] = true
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
