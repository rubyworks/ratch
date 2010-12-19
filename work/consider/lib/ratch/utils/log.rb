require 'ratch/plugin'

module Ratch

  # Logging utils.
  module Logging

    # Access a log by name.
    def log(path)
      @logfile ||= {}
      @logfile[path.to_s] ||= (
        Log.new(project.log + name.to_s, :noop=>noop?, :verbose=>verbose?)
      )
    end

    # The Log class provides a common and easy to use means for
    # different services to log there activity.
    #
    class Log

      attr :pathname

      #
      def initialize(pathname, options={})
        @pathname = Pathname.new(pathname)
        @noop    = options[:noop]
        @verbose = options[:verbose]
      end

      def noop?    ; @noop    ; end

      def verbose? ; @verbose ; end

      #
      def method_missing(s, *a, &b)
        @pathname.send(s, *a, &b)
      end

      # Get the path name as string.
      def file
        @pathname.to_s
      end

      # Write to log file.
      def write(str)
        return if noop?
        FileUtils.mkdir_p(File.dirname(file)) #unless File.file?(file)
        File.open(file, 'w'){ |f| f << str }
      end
      alias_method :<<, :write

      #
      def append(str)
        return if noop?
        FileUtils.mkdir_p(File.dirname(file)) #unless File.file?(file)
        File.open(file, 'a'){ |f| f << str }
      end

      #
      def clear
        return if noop?
        File.open(file, 'w'){ |f| f << '' } if File.file?(file)
      end

    end

  end

end
