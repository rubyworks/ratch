=begin
module Ratch

  # = Runmode
  #
  # The Runmode class encapsulates common options for command line scripts.
  # The built-in modes are:
  #
  #   force
  #   trace
  #   debug
  #   quiet
  #   verbose
  #   pretend -or- dryrun
  # 
  class Runmode

    def self.load_argv!
      options = {
        :force   => %w{--force}.any?{ |x| ARGV.delete(x) },
        :trace   => %w{--trace}.any?{ |x| ARGV.delete(x) },
        :debug   => %w{--debug}.any?{ |x| ARGV.delete(x) },
        :quiet   => %w{--quiet --silent}.any?{ |x| ARGV.delete(x) },
        :pretend => %w{--pretend --dryrun --dry-run}.any?{ |x| ARGV.delete(x) },
        :verbose => %w{--verbose}.any?{ |x| ARGV.delete(x) }
      }
      new(options)
    end

    def initialize(options={})
      options.rekey(&:to_sym)

      @force   = options[:force]
      @trace   = options[:trace]
      @debug   = options[:debug]
      @quiet   = options[:quiet]   || options[:silent]
      @pretend = options[:pretend] || options[:dryrun]
      @verbose = options[:verbose]
    end

    attr_accessor :force

    attr_accessor :trace

    attr_accessor :verbose

    attr_accessor :quiet

    attr_accessor :debug

    attr_accessor :pretend

    def force?   ; @force   ; end
    def trace?   ; @trace   ; end
    def debug?   ; @debug   ; end
    def quiet?   ; @quiet   ; end
    def verbose? ; @verbose ; end
    def pretend? ; @pretend ; end

    def noharm?  ; @pretend ; end
    def dryrun?  ; @pretend ; end
  end

end
=end

