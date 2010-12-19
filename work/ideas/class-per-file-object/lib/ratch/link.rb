require 'folio/fileobject'

module Folio

  class Link < FileObject

    def initialize(path)
      super
      raise LinkNotFound, "#{path}" unless ::File.symlink?(@path)

      dir  = ::File.dirname(@path)
      name = ::File.readlink(@path)
      file = File.join(dir, name)

      @target = Folio.file(file)
    end

    attr :target

    #--
    # Am I write to think any file object can be linked?
    #++

    def symlink?
      ::File.symlink?(path)
    end
    alias_method :link?, :symlink?
    
    def readlink
      ::File.readlink(path)
    end

    def lchmod(mode)
      ::File.lchmod(mode, path)
    end

    def lchown(own, grp)
      ::File.lchown(own, grp, path)
    end

    def lstat
      ::File.lstat(path)
    end

    #
    def method_missing(s, *a, &b)
      @target.send(s, *a, &b)
    end

  end

end
