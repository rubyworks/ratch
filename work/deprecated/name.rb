#--
# = path/name.rb
#
# Object-Oriented Pathname Class
#
# Author:: Tanaka Akira <akr@m17n.org>
# Documentation:: Author and Gavin Sinclair
#
# For documentation, see class Pathname.
#
# <tt>pathname.rb</tt> is distributed with Ruby since 1.8.0.
#
# THIS IS AN IMPROVED VERSION THAT USES AN ARRAY INSTEAD OF A STRING FOR PATH.
#
# A modified version of Pathname that uses an array internal rather then a string.
# This gave ~20% performance boot. Unfortunately no one cared.
#++

module Path
  require 'path/list'

  # == Path::Name
  #
  # Path::Name represents a pathname which locates a file in a filesystem.
  # It supports only Unix style pathnames.  It does not represent the file
  # itself.  A Path::Name can be relative or absolute.  It's not until you try to
  # reference the file that it even matters whether the file exists or not.
  #
  # Path::Name is immutable.  It has no method for destructive update.
  #
  # The value of this class is to manipulate file path information in a neater
  # way than standard Ruby provides.  The examples below demonstrate the
  # difference.  *All* functionality from File, FileTest, and some from Dir and
  # FileUtils is included, in an unsurprising way.  It is essentially a facade for
  # all of these, and more.
  #
  # == Examples
  #
  # === Example 1: Using Path::Name
  #
  #   require 'pathname'
  #   p = Path::Name.new("/usr/bin/ruby")
  #   size = p.size              # 27662
  #   isdir = p.directory?       # false
  #   dir  = p.dirname           # Path::Name:/usr/bin
  #   base = p.basename          # Path::Name:ruby
  #   dir, base = p.split        # [Path::Name:/usr/bin, Path::Name:ruby]
  #   data = p.read
  #   p.open { |f| _ }
  #   p.each_line { |line| _ }
  #
  # === Example 2: Using standard Ruby
  #
  #   p = "/usr/bin/ruby"
  #   size = File.size(p)        # 27662
  #   isdir = File.directory?(p) # false
  #   dir  = File.dirname(p)     # "/usr/bin"
  #   base = File.basename(p)    # "ruby"
  #   dir, base = File.split(p)  # ["/usr/bin", "ruby"]
  #   data = File.read(p)
  #   File.open(p) { |f| _ }
  #   File.foreach(p) { |line| _ }
  #
  # === Example 3: Special features
  #
  #   p1 = Path::Name.new("/usr/lib")   # Path::Name:/usr/lib
  #   p2 = p1 + "ruby/1.8"            # Path::Name:/usr/lib/ruby/1.8
  #   p3 = p1.parent                  # Path::Name:/usr
  #   p4 = p2.relative_path_from(p3)  # Path::Name:lib/ruby/1.8
  #   pwd = Path::Name.pwd              # Path::Name:/home/gavin
  #   pwd.absolute?                   # true
  #   p5 = Path::Name.new "."           # Path::Name:.
  #   p5 = p5 + "music/../articles"   # Path::Name:music/../articles
  #   p5.cleanpath                    # Path::Name:articles
  #   p5.realpath                     # Path::Name:/home/gavin/articles
  #   p5.children                     # [Path::Name:/home/gavin/articles/linux, ...]
  #
  # == Breakdown of functionality
  #
  # === Core methods
  #
  # These methods are effectively manipulating a String, because that's all a path
  # is.  Except for #mountpoint?, #children, and #realpath, they don't access the
  # filesystem.
  #
  # - +
  # - #join
  # - #parent
  # - #root?
  # - #absolute?
  # - #relative?
  # - #relative_path_from
  # - #each_filename
  # - #cleanpath
  # - #realpath
  # - #children
  # - #mountpoint?
  #
  # === File status predicate methods
  #
  # These methods are a facade for FileTest:
  # - #blockdev?
  # - #chardev?
  # - #directory?
  # - #executable?
  # - #executable_real?
  # - #exist?
  # - #file?
  # - #grpowned?
  # - #owned?
  # - #pipe?
  # - #readable?
  # - #readable_real?
  # - #setgid?
  # - #setuid?
  # - #size
  # - #size?
  # - #socket?
  # - #sticky?
  # - #symlink?
  # - #writable?
  # - #writable_real?
  # - #zero?
  #
  # === File property and manipulation methods
  #
  # These methods are a facade for File:
  # - #atime
  # - #ctime
  # - #mtime
  # - #chmod(mode)
  # - #lchmod(mode)
  # - #chown(owner, group)
  # - #lchown(owner, group)
  # - #fnmatch(pattern, *args)
  # - #fnmatch?(pattern, *args)
  # - #ftype
  # - #make_link(old)
  # - #open(*args, &block)
  # - #readlink
  # - #rename(to)
  # - #stat
  # - #lstat
  # - #make_symlink(old)
  # - #truncate(length)
  # - #utime(atime, mtime)
  # - #basename(*args)
  # - #dirname
  # - #extname
  # - #expand_path(*args)
  # - #split
  #
  # === Directory methods
  #
  # These methods are a facade for Dir:
  # - Path::Name.glob(*args)
  # - Path::Name.getwd / Path::Name.pwd
  # - #rmdir
  # - #entries
  # - #each_entry(&block)
  # - #mkdir(*args)
  # - #opendir(*args)
  #
  # === IO
  #
  # These methods are a facade for IO:
  # - #each_line(*args, &block)
  # - #read(*args)
  # - #readlines(*args)
  # - #sysopen(*args)
  #
  # === Utilities
  #
  # These methods are a mixture of Find, FileUtils, and others:
  # - #find(&block)
  # - #mkpath
  # - #rmtree
  # - #unlink / #delete
  #
  #
  # == Method documentation
  #
  # As the above section shows, most of the methods in Path::Name are facades.  The
  # documentation for these methods generally just says, for instance, "See
  # FileTest.writable?", as you should be familiar with the original method
  # anyway, and its documentation (e.g. through +ri+) will contain more
  # information.  In some cases, a brief description will follow.
  #
  class Name

    class << self

      def create( path=[], abs=false, trail=false )
        o = self.allocate
        o.instance_variable_set("@path", path.dup)
        o.instance_variable_set("@absolute", abs ? true : false)
        o.instance_variable_set("@trail", trail ? true : false)
        o
      end

      def [](path)
        new(path)
      end
    end

    # Create a Path::Name object from the given String (or String-like object).
    # If +path+ contains a NUL character (<tt>\0</tt>), an ArgumentError is raised.
    #
    def initialize(*path)
      path = path.join('/')
      @absolute = path[0,1] == '/' ? true : false
      @trail = (path.size > 1 and path[-1,1] == '/') ? true : false
      @path = path.split(%r{/})
      @path.delete('')

      #case path
      #when Path::Name
      #  @path = path.pathlist.dup
      #  @absolute = path.absolute?
      #when Array
      #  @path = path.collect{|e| e.to_str}
      #  @absolute = absolute
      #else
      #  path = path.to_str if path.respond_to?(:to_str)
      #  raise ArgumentError, "pathname contains \\0: #{@path.inspect}" if /\0/ =~ @path
      #  @path = path.split(%r{/})
      #  @path.unshift('') if path[0,1] == '/'  # absolute path
      #end

      self.taint if path.tainted?
    end

    def freeze()  super ; @path.freeze  ; self end
    def taint()   super ; @path.taint   ; self end
    def untaint() super ; @path.untaint ; self end

    # Convertion method for path names. This returns self.
    def to_path
      self
    end

    #
    def [](*globs)
      Path::List.new(self)[*globs]
    end

    # Stores the array of the componet parts of the pathname.
    #
    # protected
    def pathlist
      @path
    end

    # Compare this pathname with +other+.  The comparison is string-based.
    # Be aware that two different paths (<tt>foo.txt</tt> and <tt>./foo.txt</tt>)
    # can refer to the same file.
    #
    def ==(other)
      return false unless Path::Name === other
      if @absolute
        return false unless other.absolute?
      end
      @path == other.pathlist
    end
    alias_method :===, :==
    alias_method :eql?, :==

    # Provides for comparing pathnames, case-sensitively.
    def <=>(other)
      return nil unless Path::Name === other
      return 1 if absolute? and not other.absolute?
      return -1 if other.absolute? and not absolute?
      r = @path <=> other.pathlist
      return r unless r == 0
      return 1 if trail? and not other.trail?
      return -1 if other.trail? and not trail?
      0
    end

    def hash # :nodoc:
      to_s.hash
    end

    # Return the path as a String (same as to_s).
    def path
      s = ''
      s << '/' if @absolute
      s << @path.join('/')
      s << '/' if @trail
      s << '.' if s.empty?
      s
    end

    # Return the path as a String (same as pathname).
    def to_s
      s = ''
      s << '/' if @absolute
      s << @path.join('/')
      s << '/' if @trail
      s << '.' if s.empty?
      s
    end

    # to_str is implemented so Path::Name objects are usable with File.open, etc.
    alias_method :to_str, :to_s

    def inspect # :nodoc:
      "#<#{self.class}: #{to_s}>"
    end

    # append directory or file name to path
    def <<(name)
      name = name.to_str
      @path << name unless name.strip.empty?
      @path
    end

    #
    # Returns clean pathname of +self+ with consecutive slashes and useless dots
    # removed.  The filesystem is not accessed.
    #
    # If +consider_symlink+ is +true+, then a more conservative algorithm is used
    # to avoid breaking symbolic linkages.  This may retain more <tt>..</tt>
    # entries than absolutely necessary, but without accessing the filesystem,
    # this can't be avoided.  See #realpath.
    #
    def cleanpath(consider_symlink=false)
      if consider_symlink
        cleanpath_conservative
      else
        cleanpath_aggressive
      end
    end

    # Clean the path simply by resolving and removing excess "." and ".." entries.
    # Nothing more, nothing less.
    #
    def cleanpath_aggressive
      # cleanpath_aggressive assumes:
      # * no symlink
      # * all pathname prefix contained in the pathname is existing directory
      return Path::Name.create([],@absolute,@trail) if path.empty?
      absolute = absolute?
      trail = trail?
      names = []
      @path.each {|name|
        next if name == '.'
        if name == '..'
          if names.empty?
            next if absolute
          else
            if names.last != '..'
              names.pop
              next
            end
          end
        end
        names << name
      }
      return Path::Name.new(absolute ? '/' : '.') if names.empty?
      #path = []
      #path << '' if absolute
      #path.concat(names)
      Path::Name.create(names, absolute) #, trail)
    end
    private :cleanpath_aggressive

    def cleanpath_conservative
      return Path::Name.create([],@absolute) if @path.empty?
      names = @path.dup #.scan(%r{[^/]+})
      last_dot = (names.last == '.')
      names.delete('.')
      names.shift while names.first == '..' if absolute?
      return Path::Name.new(absolute? ? '/' : '.') if names.empty?
      newpath = []
      trail = false
      #newpath << '' if absolute?
      newpath.concat(names)
      if names.last != '..'
        if last_dot
          newpath << '.'
        elsif trail? #%r{/\z} =~ @path  #HOW TO DEAL WITH TRAILING '/' ?
          trail = true
        end
      end
      Path::Name.create(newpath, absolute?, trail)
    end
    private :cleanpath_conservative

    #
    # Returns a real (absolute) pathname of +self+ in the actual filesystem.
    # The real pathname doesn't contain symlinks or useless dots.
    #
    # No arguments should be given; the old behaviour is *obsoleted*.
    #
    def realpath(*args)
      unless args.empty?
        warn "The argument for Path::Name#realpath is obsoleted."
      end
      force_absolute = args.fetch(0, true)

      if @path.first == ''
        top = '/'
        unresolved = @path.slice(1..-1) #.scan(%r{[^/]+})
      elsif force_absolute
        # Although POSIX getcwd returns a pathname which contains no symlink,
        # 4.4BSD-Lite2 derived getcwd may return the environment variable $PWD
        # which may contain a symlink.
        # So the return value of Dir.pwd should be examined.
        top = '/'
        unresolved = Dir.pwd.split(%r{/}) + @path
      else
        top = ''
        unresolved = @path.dup #.scan(%r{[^/]+})
      end
      resolved = []

      until unresolved.empty?
        case unresolved.last
        when '.'
          unresolved.pop
        when '..'
          resolved.unshift unresolved.pop
        else
          loop_check = {}
          while (stat = File.lstat(path = top + unresolved.join('/'))).symlink?
            symlink_id = "#{stat.dev}:#{stat.ino}"
            raise Errno::ELOOP.new(path) if loop_check[symlink_id]
            loop_check[symlink_id] = true
            if %r{\A/} =~ (link = File.readlink(path))
              top = '/'
              unresolved = link.split(%r{/}) #scan(%r{[^/]+})
            else
              unresolved[-1,1] = link.split(%r{/}) #.scan(%r{[^/]+})
            end
          end
          next if (filename = unresolved.pop) == '.'
          if filename != '..' && resolved.first == '..'
            resolved.shift
          else
            resolved.unshift filename
          end
        end
      end

      if top == '/'
        resolved.shift while resolved[0] == '..'
      end

      if resolved.empty?
        Path::Name.new(top.empty? ? '.' : '/')
      else
        if top.empty?
          Path::Name.new(resolved)
        else
          Path::Name.new(resolved, true)
        end
      end
    end

    # #parent returns the parent directory.
    #
    # This is same as <tt>self + '..'</tt>.
    def parent
      self << '..'
    end

    # #mountpoint? returns +true+ if <tt>self</tt> points to a mountpoint.
    def mountpoint?
      begin
        stat1 = self.lstat
        stat2 = self.parent.lstat
        stat1.dev == stat2.dev && stat1.ino == stat2.ino ||
          stat1.dev != stat2.dev
      rescue Errno::ENOENT
        false
      end
    end

    #
    # #root? is a predicate for root directories.  I.e. it returns +true+ if the
    # pathname consists of consecutive slashes.
    #
    # It doesn't access actual filesystem.  So it may return +false+ for some
    # pathnames which points to roots such as <tt>/usr/..</tt>.
    #
    def root?
      #%r{\A/+\z} =~ @path ? true : false
      @absolute and @path.empty?
    end

    def current?
      #%r{\A/+\z} =~ @path ? true : false
      (!@absolute) and @path.empty?
    end

    # Predicate method for testing whether a path is absolute.
    # It returns +true+ if the pathname begins with a slash.
    def absolute?
      #%r{\A/} =~ @path ? true : false
      @absolute
    end

    # The opposite of #absolute?
    def relative?
      !@absolute
    end

    def trail?
      @trail
    end

    #
    # Iterates over each component of the path.
    #
    #   Path::Name.new("/usr/bin/ruby").each_filename {|filename| ... }
    #     # yields "usr", "bin", and "ruby".
    #
    def each_filename # :yield: e
      #@path.scan(%r{[^/]+}) { yield $& }
      @path.each { |e| yield e }
    end

    #
    # Path::Name#+ appends a pathname fragment to this one to produce a new Path::Name
    # object.
    #
    #   p1 = Path::Name.new("/usr")      # Path::Name:/usr
    #   p2 = p1 + "bin/ruby"           # Path::Name:/usr/bin/ruby
    #   p3 = p1 + "/etc/passwd"        # Path::Name:/etc/passwd
    #
    # This method doesn't access the file system; it is pure string manipulation.
    #
    def +(other)
      path = self.class.new(File.join(to_s, other.to_s))
      path.cleanpath

      #other = Path::Name.new(other) unless Path::Name === other
      #return other if other.absolute?
      #pth = (@path + other.pathlist)
      #pth.delete('.')
      #Path::Name.create(pth, @absolute, other.trail?)

  #    path1 = @path#
  #    path2 = other.to_s
  #    while m2 = %r{\A\.\.(?:/+|\z)}.match(path2) and
  #          m1 = %r{(\A|/+)([^/]+)\z}.match(path1) and
  #          %r{\A(?:\.|\.\.)\z} !~ m1[2]
  #      path1 = m1[1].empty? ? '.' : '/' if (path1 = m1.pre_match).empty?
  #      path2 = '.' if (path2 = m2.post_match).empty?
  #    end
  #    if %r{\A/+\z} =~ path1
  #      while m2 = %r{\A\.\.(?:/+|\z)}.match(path2)
  #        path2 = '.' if (path2 = m2.post_match).empty?
  #      end
  #    end
  #
  #    return Path::Name.new(path2) if path1 == '.'
  #    return Path::Name.new(path1) if path2 == '.'
  #
  #    if %r{/\z} =~ path1
  #      Path::Name.new(path1 + path2)
  #    else
  #      Path::Name.new(path1 + '/' + path2)
  #    end
    end

    #
    alias_method :/, :+      #/ kate highlight fix

    #
    # Path::Name#join joins pathnames.
    #
    # <tt>path0.join(path1, ..., pathN)</tt> is the same as
    # <tt>path0 + path1 + ... + pathN</tt>.
    #
    # HELP ME!!!
    #
    def join(*args)
      Path::Name.new(*args)
      #args.unshift self
      #result = args.pop
      #result = Path::Name.new(result) unless Path::Name === result
      #return result if result.absolute?
      #args.reverse_each {|arg|
      #  arg = Path::Name.new(arg) unless Path::Name === arg
      #  result = arg + result
      #  return result if result.absolute?
      #}
      #result
    end

    #
    # Returns the children of the directory (files and subdirectories, not
    # recursive) as an array of Path::Name objects.  By default, the returned
    # pathnames will have enough information to access the files.  If you set
    # +with_directory+ to +false+, then the returned pathnames will contain the
    # filename only.
    #
    # For example:
    #   p = Path::Name("/usr/lib/ruby/1.8")
    #   p.children
    #       # -> [ Path::Name:/usr/lib/ruby/1.8/English.rb,
    #              Path::Name:/usr/lib/ruby/1.8/Env.rb,
    #              Path::Name:/usr/lib/ruby/1.8/abbrev.rb, ... ]
    #   p.children(false)
    #       # -> [ Path::Name:English.rb, Path::Name:Env.rb, Path::Name:abbrev.rb, ... ]
    #
    # Note that the result never contain the entries <tt>.</tt> and <tt>..</tt> in
    # the directory because they are not children.
    #
    # This method has existed since 1.8.1.
    #
    def children(with_directory=true)
      with_directory = false if @path == ['.']
      result = []
      Dir.foreach(to_s) {|e|
        next if e == '.' || e == '..'
        if with_directory
          result << Path::Name.create(@path + [e], absolute?)
        else
          result << Path::Name.new(e)
        end
      }
      result
    end

    #
    # #relative_path_from returns a relative path from the argument to the
    # receiver.  If +self+ is absolute, the argument must be absolute too.  If
    # +self+ is relative, the argument must be relative too.
    #
    # #relative_path_from doesn't access the filesystem.  It assumes no symlinks.
    #
    # ArgumentError is raised when it cannot find a relative path.
    #
    # This method has existed since 1.8.1.
    #
    def relative_path_from(base_directory)
      if self.absolute? != base_directory.absolute?
        raise ArgumentError,
          "relative path between absolute and relative path: #{self.inspect}, #{base_directory.inspect}"
      end

      dest = []
      self.cleanpath.each_filename {|f|
        next if f == '.'
        dest << f
      }

      base = []
      base_directory.cleanpath.each_filename {|f|
        next if f == '.'
        base << f
      }

      while !base.empty? && !dest.empty? && base[0] == dest[0]
        base.shift
        dest.shift
      end

      if base.include? '..'
        raise ArgumentError, "base_directory has ..: #{base_directory.inspect}"
      end

      base.fill '..'
      relpath = base + dest
      if relpath.empty?
        Path::Name.new('.')
      else
        Path::Name.create(relpath, false) #.join('/'))
      end
    end

    #
    def rootname
      # this should be fairly robust
      path_re = Regexp.new('[' + Regexp.escape(File::Separator + %q{\/}) + ']')
      head, tail = path.split(path_re, 2)
      return '.' if path == head
      return '/' if head.empty?
      self.class.new(head)
    end

    # Calls the _block_ for every successive parent directory of the
    # directory path until the root (absolute path) or +.+ (relative path)
    # is reached.
    def ascend(inclusive=false,&block) # :yield:
      cur_dir = self
      yield( cur_dir.cleanpath ) if inclusive
      until cur_dir.root? or cur_dir == self.class.new(".")
        cur_dir = cur_dir.parent
        yield cur_dir
      end
    end

    # Calls the _block_ for every successive subdirectory of the
    # directory path from the root (absolute path) until +.+
    # (relative path) is reached.
    def descend()
      @path.scan(%r{[^/]*/?})[0...-1].inject('') do |path, dir|
        yield self.class.new(path << dir)
        path
      end
    end

    #
    def split_root
      path_re = Regexp.new('[' + Regexp.escape(File::Separator + %q{\/}) + ']')
      head, tail = *path.split(path_re, 2)
      [self.class.new(head), self.class.new(tail)]
    end
  end


  class Path::Name    # * IO *
    #
    # #each_line iterates over the line in the file.  It yields a String object
    # for each line.
    #
    # This method has existed since 1.8.1.
    #
    def each_line(*args, &block) # :yield: line
      IO.foreach(path, *args, &block)
    end

    # Path::Name#foreachline is *obsoleted* at 1.8.1.  Use #each_line.
    def foreachline(*args, &block)
      warn "Path::Name#foreachline is obsoleted.  Use Path::Name#each_line."
      each_line(*args, &block)
    end

    # See <tt>IO.read</tt>.  Returns all the bytes from the file, or the first +N+
    # if specified.
    def read(*args) IO.read(path, *args) end

    # See <tt>IO.readlines</tt>.  Returns all the lines from the file.
    def readlines(*args) IO.readlines(path, *args) end

    # See <tt>IO.sysopen</tt>.
    def sysopen(*args) IO.sysopen(path, *args) end
  end


  class Path::Name    # * File *

    # See <tt>File.atime</tt>.  Returns last access time.
    def atime() File.atime(path) end

    # See <tt>File.ctime</tt>.  Returns last (directory entry, not file) change time.
    def ctime() File.ctime(path) end

    # See <tt>File.mtime</tt>.  Returns last modification time.
    def mtime() File.mtime(path) end

    # See <tt>File.chmod</tt>.  Changes permissions.
    def chmod(mode) File.chmod(mode, path) end

    # See <tt>File.lchmod</tt>.
    def lchmod(mode) File.lchmod(mode, path) end

    # See <tt>File.chown</tt>.  Change owner and group of file.
    def chown(owner, group) File.chown(owner, group, path) end

    # See <tt>File.lchown</tt>.
    def lchown(owner, group) File.lchown(owner, group, path) end

    # See <tt>File.fnmatch</tt>.  Return +true+ if the receiver matches the given
    # pattern.
    def fnmatch(pattern, *args) File.fnmatch(pattern, path, *args) end

    # See <tt>File.fnmatch?</tt> (same as #fnmatch).
    def fnmatch?(pattern, *args) File.fnmatch?(pattern, path, *args) end

    # See <tt>File.ftype</tt>.  Returns "type" of file ("file", "directory",
    # etc).
    def ftype() File.ftype(path) end

    # See <tt>File.link</tt>.  Creates a hard link.
    def make_link(old) File.link(old, path) end

    # See <tt>File.open</tt>.  Opens the file for reading or writing.
    def open(*args, &block) # :yield: file
      File.open(path, *args, &block)
    end

    # See <tt>File.readlink</tt>.  Read symbolic link.
    def readlink() Path::Name.new(File.readlink(path)) end

    # See <tt>File.rename</tt>.  Rename the file.
    def rename(to) File.rename(path, to) end

    # See <tt>File.stat</tt>.  Returns a <tt>File::Stat</tt> object.
    def stat() File.stat(path) end

    # See <tt>File.lstat</tt>.
    def lstat() File.lstat(path) end

    # See <tt>File.symlink</tt>.  Creates a symbolic link.
    def make_symlink(old) File.symlink(old, path) end

    # See <tt>File.truncate</tt>.  Truncate the file to +length+ bytes.
    def truncate(length) File.truncate(path, length) end

    # See <tt>File.utime</tt>.  Update the access and modification times.
    def utime(atime, mtime) File.utime(atime, mtime, path) end

    # See <tt>File.basename</tt>.  Returns the last component of the path.
    def basename(*args) Path::Name.new(File.basename(path, *args)) end

    # See <tt>File.dirname</tt>.  Returns all but the last component of the path.
    def dirname() Path::Name.new(File.dirname(path)) end

    # See <tt>File.extname</tt>.  Returns the file's extension.
    def extname() File.extname(path) end

    # See <tt>File.expand_path</tt>.
    def expand_path(*args) Path::Name.new(File.expand_path(path, *args)) end

    # See <tt>File.split</tt>.  Returns the #dirname and the #basename in an
    # Array.
    def split() File.split(path).map {|f| Path::Name.new(f) } end

    # Path::Name#link is confusing and *obsoleted* because the receiver/argument
    # order is inverted to corresponding system call.
    def link(old)
      warn 'Path::Name#link is obsoleted.  Use Path::Name#make_link.'
      File.link(old, path)
    end

    # Path::Name#symlink is confusing and *obsoleted* because the receiver/argument
    # order is inverted to corresponding system call.
    def symlink(old)
      warn 'Path::Name#symlink is obsoleted.  Use Path::Name#make_symlink.'
      File.symlink(old, path)
    end
  end


  class Path::Name    # * FileTest *

    # See <tt>FileTest.blockdev?</tt>.
    def blockdev?() FileTest.blockdev?(path) end

    # See <tt>FileTest.chardev?</tt>.
    def chardev?() FileTest.chardev?(path) end

    # See <tt>FileTest.executable?</tt>.
    def executable?() FileTest.executable?(path) end

    # See <tt>FileTest.executable_real?</tt>.
    def executable_real?() FileTest.executable_real?(path) end

    # See <tt>FileTest.exist?</tt>.
    def exist?() FileTest.exist?(path) end

    # See <tt>FileTest.grpowned?</tt>.
    def grpowned?() FileTest.grpowned?(path) end

    # See <tt>FileTest.directory?</tt>.
    def directory?() FileTest.directory?(path) end

    # Like directory? but return self if true, otherwise nil.
    def dir? ; directory? ? self : nil ; end

    # See <tt>FileTest.file?</tt>.
    def file?() FileTest.file?(path) end

    # See <tt>FileTest.pipe?</tt>.
    def pipe?() FileTest.pipe?(path) end

    # See <tt>FileTest.socket?</tt>.
    def socket?() FileTest.socket?(path) end

    # See <tt>FileTest.owned?</tt>.
    def owned?() FileTest.owned?(path) end

    # See <tt>FileTest.readable?</tt>.
    def readable?() FileTest.readable?(path) end

    # See <tt>FileTest.readable_real?</tt>.
    def readable_real?() FileTest.readable_real?(path) end

    # See <tt>FileTest.setuid?</tt>.
    def setuid?() FileTest.setuid?(path) end

    # See <tt>FileTest.setgid?</tt>.
    def setgid?() FileTest.setgid?(path) end

    # See <tt>FileTest.size</tt>.
    def size() FileTest.size(path) end

    # See <tt>FileTest.size?</tt>.
    def size?() FileTest.size?(path) end

    # See <tt>FileTest.sticky?</tt>.
    def sticky?() FileTest.sticky?(path) end

    # See <tt>FileTest.symlink?</tt>.
    def symlink?() FileTest.symlink?(path) end

    # See <tt>FileTest.writable?</tt>.
    def writable?() FileTest.writable?(path) end

    # See <tt>FileTest.writable_real?</tt>.
    def writable_real?() FileTest.writable_real?(path) end

    # See <tt>FileTest.zero?</tt>.
    def zero?() FileTest.zero?(path) end
  end


  class Path::Name    # * Dir *
    # See <tt>Dir.glob</tt>.  Returns or yields Path::Name objects.
    def self.glob(*args) # :yield: p
      if block_given?
        Dir.glob(*args) {|f| yield Path::Name.new(f) }
      else
        Dir.glob(*args).map {|f| Path::Name.new(f) }
      end
    end

    # See <tt>Dir.getwd</tt>.  Returns the current working directory as a Path::Name.
    def self.getwd() Path::Name.new(Dir.getwd) end
    class << self; alias pwd getwd end

    # Path::Name#chdir is *obsoleted* at 1.8.1.
    def chdir(&block)
      warn "Path::Name#chdir is obsoleted.  Use Dir.chdir."
      Dir.chdir(path, &block)
    end

    # Path::Name#chroot is *obsoleted* at 1.8.1.
    def chroot
      warn "Path::Name#chroot is obsoleted.  Use Dir.chroot."
      Dir.chroot(path)
    end

    # Return the entries (files and subdirectories) in the directory, each as a
    # Path::Name object.
    def entries() Dir.entries(path).map {|f| Path::Name.new(f) } end

    # Iterates over the entries (files and subdirectories) in the directory.  It
    # yields a Path::Name object for each entry.
    #
    # This method has existed since 1.8.1.
    def each_entry(&block) # :yield: p
      Dir.foreach(path) {|f| yield Path::Name.new(f) }
    end

    # Path::Name#dir_foreach is *obsoleted* at 1.8.1.
    def dir_foreach(*args, &block)
      warn "Path::Name#dir_foreach is obsoleted.  Use Path::Name#each_entry."
      each_entry(*args, &block)
    end

    # See <tt>Dir.mkdir</tt>.  Create the referenced directory.
    def mkdir(*args) Dir.mkdir(path, *args) end

    # See <tt>Dir.rmdir</tt>.  Remove the referenced directory.
    def rmdir() Dir.rmdir(path) end

    # See <tt>Dir.open</tt>.
    def opendir(&block) # :yield: dir
      Dir.open(path, &block)
    end

    #
    def glob(match, *opts)
      flags = 0
      opts.each do |opt|
        case opt when Symbol, String
          flags += ::File.const_get("FNM_#{opt}".upcase)
        else
          flags += opt
        end
      end
      Dir.glob(::File.join(self.to_s, match), flags).collect{ |m| self.class.new(m) }
    end

    # Like #glob but returns the first match.
    def first(match, *opts)
      flags = 0
      opts.each do |opt|
        case opt when Symbol, String
          flags += ::File.const_get("FNM_#{opt}".upcase)
        else
          flags += opt
        end
      end
      file = ::Dir.glob(::File.join(self.to_s, match), flags).first
      file ? self.class.new(file) : nil
    end

    # DEPRECATE
    alias_method :glob_first, :first

    # Like #glob but returns the last match.
    def last(match, *opts)
      flags = 0
      opts.each do |opt|
        case opt when Symbol, String
          flags += ::File.const_get("FNM_#{opt}".upcase)
        else
          flags += opt
        end
      end
      file = ::Dir.glob(::File.join(self.to_s, match), flags).last
      file ? self.class.new(file) : nil
    end

    # DEPRECATE
    alias_method :glob_last, :last

    #
    def empty?
      Dir.glob(::File.join(self.to_s, '*')).empty?
    end
  end


  class Path::Name    # * Find *
    # Path::Name#find is an iterator to traverse a directory tree in a depth first
    # manner.  It yields a Path::Name for each file under "this" directory.
    #
    # Since it is implemented by <tt>find.rb</tt>, <tt>Find.prune</tt> can be used
    # to control the traverse.
    #
    # If +self+ is <tt>.</tt>, yielded pathnames begin with a filename in the
    # current directory, not <tt>./</tt>.
    #
    # TODO: This is more like and #each method, though also like #descend. 
    # I would rather use the method name #find in place of #first. This would be a
    # non-compatability with Pathname, but I think an acceptable one. Need to
    # compare #descend to #find. We may not even need both.

    def find(&block) # :yield: p
      require 'find'
      if @path == ['.']
        Find.find(path) {|f| yield Path::Name.new(f.sub(%r{\A\./}, '')) }
      else
        Find.find(path) {|f| yield Path::Name.new(f) }
      end
    end
  end


  class Path::Name    # * FileUtils *
    # See <tt>FileUtils.mkpath</tt>.  Creates a full path, including any
    # intermediate directories that don't yet exist.
    def mkpath
      require 'fileutils'
      FileUtils.mkpath(path)
      nil
    end

    # See <tt>FileUtils.rm_r</tt>.  Deletes a directory and all beneath it.
    def rmtree
      # The name "rmtree" is borrowed from File::Path of Perl.
      # File::Path provides "mkpath" and "rmtree".
      require 'fileutils'
      FileUtils.rm_r(path)
      nil
    end

    #
    def uptodate?(*sources)
      ::FileUtils.uptodate?(to_s, sources.flatten)
    end

    #
    def outofdate?(*sources)
      ! uptodate?(*sources)
    end
  end


  class Path::Name    # * mixed *
    # Removes a file or directory, using <tt>File.unlink</tt> or
    # <tt>Dir.unlink</tt> as necessary.
    def unlink()
      begin
        Dir.unlink path
      rescue Errno::ENOTDIR
        File.unlink path
      end
    end
    alias delete unlink

    # This method is *obsoleted* at 1.8.1.  Use #each_line or #each_entry.
    def foreach(*args, &block)
      warn "Path::Name#foreach is obsoleted.  Use each_line or each_entry."
      if FileTest.directory? path
        # For polymorphism between Dir.foreach and IO.foreach,
        # Path::Name#foreach doesn't yield Path::Name object.
        Dir.foreach(path, *args, &block)
      else
        IO.foreach(path, *args, &block)
      end
    end
  end

  class Path::Name  # extensions

    # Alternate to Pathname#new.
    #
    #   Pathname['/usr/share']
    #
    def self.[](path)
      new(path)
    end

    # Active path separator.
    #
    #   p1 = Pathname.new('/')
    #   p2 = p1 / 'usr' / 'share'   #=> Pathname:/usr/share
    #
    def self./(path) #/
      new(path)
    end

    # Root constant for building paths from root directory onward.
    def self.root
      self.class.new('/')
    end

    # Home constant for building paths from root directory onward.
    #
    # TODO: Pathname#home needs to be more robust.
    #
    def self.home
      self.class.new('~')
    end

    # Work constant for building paths from root directory onward.
    #
    def self.work
      self.class.new('.')
    end

    # Platform dependent null device.
    #
    def self.null
      case RUBY_PLATFORM
      when /mswin/i
        'NUL'
      when /amiga/i
        'NIL:'
      when /openvms/i
        'NL:'
      else
        '/dev/null'
      end
    end

  end

end

class String
  def to_path
    Path::Name.new(self)
  end
end

class NilClass
  # Provide platform dependent null path.
  def to_path
    Path::Name.null
  end
end
