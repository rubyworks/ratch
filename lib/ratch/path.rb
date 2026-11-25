require 'pathname'

module Ratch

  # A Path is a Pathname that belongs to a shell and keeps to its mode:
  # when the shell is in noop mode, the methods that change the file
  # system do nothing, and when it is tracing, they are reported to
  # standard error first.
  #
  #   shell = Ratch::Shell.new('project', :dryrun=>true)
  #   shell.path('tmp').rmtree    # prints "rmtree /.../project/tmp" and removes nothing
  #
  # Paths derived from one (by #+, #parent, #children and so on) belong
  # to the same shell. In every other way it is a Pathname, and equal to
  # the Pathname of the same path. A Path made without a shell behaves as
  # a Pathname.
  #
  # Files opened for writing with #open are not covered.
  class Path < ::Pathname

    #
    def initialize(path, shell=nil)
      super(path.to_s)
      @shell = shell
    end

    # The shell the path belongs to, if any.
    attr_reader :shell

    # Is the path's shell in noop mode?
    def noop?
      @shell ? !!@shell.noop? : false
    end

    # Is the path's shell tracing?
    def trace?
      @shell ? !!@shell.trace? : false
    end

    # Pathname methods that change the file system.
    WRITE_METHODS = [
      :chmod, :lchmod, :chown, :lchown, :make_link, :make_symlink,
      :rename, :truncate, :utime, :mkdir, :mkpath, :rmdir, :rmtree,
      :unlink, :delete, :write, :binwrite
    ]

    WRITE_METHODS.each do |name|
      next unless ::Pathname.method_defined?(name)
      define_method(name) do |*args, **opts, &block|
        if trace?
          shown = [:write, :binwrite].include?(name) ? [] : args
          $stderr.puts [name, self, *shown].join(' ')
        end
        super(*args, **opts, &block) unless noop?
      end
    end

    # Append text to the file.
    def append(text)
      $stderr.puts "append #{self}" if trace?
      File.open(to_s, 'a'){ |f| f << text } unless noop?
    end

    # Pathname methods that give other paths.
    DERIVING_METHODS = [
      :+, :/, :join, :parent, :dirname, :basename, :children, :entries,
      :expand_path, :realpath, :realdirpath, :cleanpath, :sub, :sub_ext,
      :relative_path_from, :readlink, :glob
    ]

    DERIVING_METHODS.each do |name|
      next unless ::Pathname.method_defined?(name)
      define_method(name) do |*args, **opts, &block|
        adopt(super(*args, **opts, &block))
      end
    end

    #
    def each_child(with_directory=true, &block)
      children(with_directory).each(&block)
    end

  private

    # Give a derived Pathname, or a list of them, to this path's shell.
    def adopt(result)
      case result
      when ::Pathname
        self.class.new(result.to_s, @shell)
      when Array
        result.map{ |r| adopt(r) }
      else
        result
      end
    end

  end

end
