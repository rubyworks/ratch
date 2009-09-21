#require 'ansi/terminal'
#require 'ansi/code'

module Ratch

  # = Ratch IO
  #
  # The IO class is used to cleanly separate out the
  # basic input/output "dialog" between user and script.
  #
  class IO

    #
    attr :cli

    attr :stdout
    attr :stderr
    attr :stdin

    #
    def initialize(cli, stdout=nil, stderr=nil, stdin=nil)
      @cli = cli
      @stdout = stdout || $stdout
      @stderr = stderr || $stderr
      @stdin  = stdin  || $stdin
    end

    def force?  ; cli.force? ; end
    def quiet?  ; cli.quiet? ; end
    def debug?  ; cli.debug? ; end
    def noop?   ; cli.noop?  ; end

    def trace?  ; cli.verbose? && cli.debug? ; end
    def dryrun? ; cli.verbose? && cli.noop?  ; end

    #
    def report(message)
      stdout.puts message unless quiet?
    end

    # Internal status report.
    #
    # Only output if verbose mode.
    #
    def status(message)
      stderr.puts message if verbose? #unless quiet?
    end

    # TODO: better name than status?
    def trace(message)
      stderr.puts message if verbose?
    end

    # Convenient method to get simple console reply.
    def ask(question, answers=nil)
      stdout.print "#{question}"
      stdout.print " [#{answers}] " if answers
      stdout.flush
      until inp = stdin.gets ; sleep 1 ; end
      inp.strip
    end

    # Ask for a password. (FIXME: only for unix so far)
    def password(prompt=nil)
      prompt ||= "Enter Password: "
      inp = ''
      stdout << "#{prompt} "
      stdout.flush
      begin
        #system "stty -echo"
        #inp = gets.chomp
        until inp = $stdin.gets
          sleep 1
        end
      ensure
        #system "stty echo"
      end
      return inp.chomp
    end

    # TODO: Until we have better support for getting input acorss platforms
    # we are using #ask only.
    def password(prompt=nil)
      prompt ||= "Enter Password: "
      ask(prompt)
    end

    #
    def print(str)
      stdout.print(str) unless quiet?
    end

    #
    def puts(str)
      stdout.puts(str) unless quiet?
    end

=begin
    # TODO: Put something like in ANSI ?
    #
    def printline(left, right='', options={})
      return if quiet?

      separator = options[:seperator] || options[:sep] || ' '
      padding   = options[:padding]   || options[:pad] || 0

      left, right = left.to_s, right.to_s

      left_size  = left.size
      right_size = right.size

      #left  = colorize(left)
      #right = colorize(right)

      l = padding
      r = -(right_size + padding)

      style  = options[:style] || []
      lstyle = options[:left]  || []
      rstyle = options[:right] || []

      left  = lstyle.inject(left) { |s, c| ansize(s, c) }
      right = rstyle.inject(right){ |s, c| ansize(s, c) }

      line = separator * screen_width
      line[l, left_size]  = left  if left_size != 0
      line[r, right_size] = right if right_size != 0

      line = style.inject(line){ |s, c| ansize(s, c) }

      puts line + ansize('', :clear)
    end

    #def printline(left, right='', options={})
    #  return if quiet?
    #
    #  separator = options[:seperator] || options[:sep] || ' '
    #  padding   = options[:padding]   || options[:pad] || 0
    #
    #  left, right = left.to_s, right.to_s
    #
    #  left_size  = left.size
    #  right_size = right.size
    #
    #  left  = colorize(left)
    #  right = colorize(right)
    #
    #  l = padding
    #  r = -(right_size + padding + 1)
    #
    #  line = separator * screen_width
    #  line[l, left_size]  = left  if left_size != 0
    #  line[r, right_size] = right if right_size != 0
    #
    #  puts line
    #end

    #
    #def colorize(text)
    #  return text unless text.color
    #  if PLATFORM =~ /win/
    #    text.to_s
    #  else
    #    Clio::ANSICode.send(text.color){ text.to_s }
    #  end
    #end

    #
    def ansize(text, code)
      #return text unless text.color
      if PLATFORM =~ /win/
        text.to_s
      else
        ANSI::Code.send(code.to_sym) + text
      end
    end

    #
    def screen_width
      #Clio::ConsoleUtils.screen_width
      ANSI::Terminal.terminal_width
    end
=end

  end

end