require 'folio/fileobject'

module Folio

  # = Pipe
  #
  # Is this the same as a FIFO?
  #
  class Pipe < FileObject

    def initialize(path)
      raise 'Pipes not yet supported.'
    end

    def pipe? ; true ; end

  end

end

