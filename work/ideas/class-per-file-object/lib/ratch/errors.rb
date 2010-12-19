module Folio

  class FileNotFound < ::IOError
    def initialize(path=nil)
      @path = path
      super
    end

    def to_str
      if @path
        "file not found -- #{@path}"
      else
        "file not found"
      end
    end
  end

  class DirNotFound < ::IOError
  end

  class LinkNotFound < ::IOError
  end

end

