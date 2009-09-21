require 'folio/fileobject'

module Folio

  # = Document
  #
  # The Document class represents a FileObject.
  #
  class Document < FileObject

    #def intialize(path)
    #  super
    #end

    def assert_exists
      raise FileNotFound.new(@path) unless ::File.file?(@path)
      raise FileNotFound.new(@path) if ::File.symlink?(@path)
    end

    #def file? ; true ; end
    def document? ; true ; end

    #--
    # FileTest::
    #++

    def executable?       ; ::FileTest.executable?(path)       ; end
    def executable_real?  ; ::FileTest.executable_real?(path)  ; end

    #--
    # File::
    #++

    # Read file in as a string.
    def read              ; ::File.read(path)                  ; end

    # Read file in as an array of lines.
    def readlines         ; ::File.readlines(path)             ; end

    # TODO: how to handle unkinking (b/c file no longer exists)
    def unlink            ; ::File.unlink(path)                ; end
    def delete            ; ::File.delete(path)                ; end

    #--
    # File.open
    #++

    def open(mode, &block)
      ::File.open(path, mode, &block)
    end

    def truncate(size)
      ::File.open(path, 'w'){|f| f.truncate(size)}
    end

    # Replace contents of file with string.
    def write(string)
      ::File.open(path, 'w'){|f| f.write(string)}
    end

    alias_method :<, :write  # NOTE: Sure about this? It means no Comparable.

    # Replace contents of file with string.
    def append(string)
      ::File.open(path, 'a'){|f| f.write(string)}
    end

    alias_method :<<, :append

    #--  
    # Can we handle other modes besides read this way?
    #++

    #flock(mode)       ; _file.flock(mode)                   ; end

    #def method_missing(s, *a, &b)
    #  _file.send(s, *a, &b)
    #end

    #private

    #def _file         ; @_file ||= ::File.new(path)           ; end
  end

end

