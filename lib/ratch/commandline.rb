require 'clio/usage'

module Ratch

  class Commandline
    attr :usage
    def initialize
      @usage = Clio::Usage.new
      @usage['--help'       , "display help"]
      @usage['--trace'      , "trace execution"]
      @usage['--debug'      , "debug mode"]
      @usage['--pretend -p' , "no disk writes"]
      @usage['--quiet   -q' , "run silently"]
      @usage['--verbose'    , "extra output"]
      @usage['--force'      , "force operations"]
      parse!
    end

    def parse!
      @cli = @usage.parse(ARGV)
    end

    def method_missing(s, *a, &b)
      @cli.send(s, *a, &b)
    end
  end

end

