require 'folio/fileobject'

module Folio

  class Directory < FileObject

    def initialize(path=nil)
      super(path || Dir.pwd)
      assert_exists if ::File.exist?(@path)
    end

    def assert_exists
      raise FileNotFound unless ::File.directory?(@path)
    end

    def directory?   ; true  ; end

    # Opens up a Folio virtual shell at this directory.
    def shell
      Folio::Shell.new(self)
    end

    # We have to use FileUtils here b/c of some obscure
    # secutiry issues.

    # Copy this directory recursively to destination.
    def cp_r(dest)
      util.cp_r(path, dest)
    end

    # Remove this directory. Fails if not empty.
    def rmdir
      util.rmdir(path)
    end
    alias_method :unlink, :rmdir
    alias_method :delete, :rmdir
    undef_method :rm

    # Remove this directory and all it's content.
    def rm_r
      util.rm_r(path)
    end

    # Remove this directory and all it's content forcefully.
    def rm_rf(list)
      util.rm_rf(path)
    end

    # Change the mode of this directory.
    #def chmod(mode)
    #  util.chmod(mode, path)
    #end

    # Change the owner of this directory.
    #def chown(user, group)
    #  util.chown(user, group, path)
    #end

    # Change the mode of this directory and all it's content
    # recursively.
    def chmod_r(mode)
      util.chmod_r(mode, path)
    end
    #alias_method :chmod_R, :chmod_r

    # Change the owner of this directory and all it's content
    # recursively.
    def chown_r(user, group)
      util.chown_r(user, group, path)
    end
    #alias_method :chown_R, :chown_r

    #--
    # ::Dir
    #++

    # Change into this directory.
    def chdir(&block)
      ::Dir.chdir(path, &block)
    end
    alias_method :cd, :chdir

    # Make this directory the file system root.
    def chroot(&block)
      ::Dir.chroot(path, &block)
    end

    # Loop over the entries (this does includes '.' and '..').
    def foreach(&block)
      ::Dir.foreach(path, &block)
    end

    # This returns a list of file names. Unlike traditional
    # Dir.entries method, this does not include '.' or '..'.
    def entries
      ::Dir.entries(path) - ['.', '..']
    end

    # Returns a list of document names.
    def document_entries
      entries.select{ |f| File.file?(File.join(path,f)) }
    end

    # Returns a list of directory names. This does not
    # include '.' or '..'.
    def directory_entries
      entries.select{ |f| File.directory?(File.join(path,f)) }
      #dirs = ::Dir.glob("#{path}/")
      #dirs.collect{ |f| f.chomp('/') }
    end

    # Returns a list of all file objects in the directory.
    def files
      entries.map{ |f| FileObject[path, f] }
    end

    # Returns a list of all documents in the directory.
    def documents
      document_entries.map{ |f| FileObject[path, f] }
    end

    # Returns a list over all directories in the directory.
    def directories
      directory_entries.map{ |f| FileObject[path, f] }
    end

    # Same as #/ method.
    def +(fname)
      FileObject[path, fname]
    end

    # Join path and return new file object.
    def /(fname)
      FileObject[path, fname]
    end

    # Find a file using +patterns+.
    def find(*patterns)
      selection = nil
      patterns.each do |pattern|
        selection = Dir.glob(File.join(path, pattern)).first
        break if selection
      end
      FileObject[selection] if selection
    end

    # Searches for files using +patterns+.
    def select(*patterns)
      selection = []
      patterns.each do |pattern|
        selection.concat(Dir.glob(File.join(path, pattern))) 
      end
      selection.map{ |s| FileObject[s] }
    end

    # Searches for files using +patterns+. This works like #select,
    # but returns file names, rather than file objects.
    def glob(*patterns)
      selection = []
      patterns.each do |pattern|
        selection.concat(Dir.glob(File.join(path, pattern))) 
      end
      selection
    end

    # Stage files from this directory at +directory+.
    #def stage(directory, *files)
    #  files = files.flatten.uniq
    #  util.stage(directory, path, files)
    #end

    def contains?(child)
      FileTest.contains?(child, path) #localize(path))
    end

  end

end

