require 'ratch/script'

module Ratch

  # = Folio Service
  #
  # The Service class is a convenience base class
  # for other classes that require extensive access
  # to the file system.
  #
  # It creates a shell object and uses method_missing
  # to delegate to it.
  #
  class Service

    attr_accessor :noop, :verbose, :dryrun

    alias_method :noop?,    :noop
    alias_method :verbose?, :verbose
    alias_method :dryrun?,  :dryrun

    # Shell
    def shell
      @fio ||= Folio::Shell.new(:noop => noop, :verbose => verbose)
    end

    # Delegate to +shell+ if it responds to the missing method.
    def method_missing(s, *a, &b)
      if shell.respond_to?(s)
        shell.__send__(s, *a, &b)
      else
        super
      end
    end

  end

end
