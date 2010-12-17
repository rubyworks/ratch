#require 'pathname'

module Folio

  class Path

    def initialize(path)
      if File.exist?(path)
        @delegate = Pathname.new(path, self)
      else
        @delegate = FileObject[path]
      end
    end

    def replace(file_object)
      @delegate = file_object
    end

    def method_missing(s, *a, &b)
      @delegate.__send__(s, *a, &b)
    end
  end


  class Pathname

    def initialize(path, delegator)

    end

    def cd
      delegator.replace(Directory.new(to_s))
      delegator.cd()
    end

  end

end




#module Kernel
#  def path(name)
#    Folio::Path.new(name)
#  end
#end

#$path = lambda{ |path| Folio::Path.new(path) }

#class String
#  def to_path
#    Folio::Path.new(self)
#  end
#end

