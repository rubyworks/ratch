require 'facets/argvector'

module Ratch

  #
  module CLI

   def initialize(*args)
     argv = ArgVector.new(ARGV)

     @arguments, parameters = *argv.parameters

     args << {} unless Hash === args.last

     opts = args.last

     opts.merge!(parameters)

     super(*args)
   end

    #
    def arguments
      @arguments
    end

    # DEPRECATE!
    #alias_method :commandline, :cli

    # DEPRECATE!
    #alias_method :command, :cli

    #
    #def commandline
    #  #@commandline ||= ArgVector.new(ARGV)
    #  @commandline
    #end
  end

end
