require 'clio/consoleutils'
require 'clio/ansicode'

module Ratch

  # = Ratch IO
  #
  # The IO class is used to cleanly separate out the
  # basic input/output "dialog" between user and script.
  #
  class IO

    #
    attr :commandline

    #
    def initialize(commandline)
      @commandline = commandline
    end

    def force?   ; commandline.force?   ; end
    def quiet?   ; commandline.quiet?   ; end
    def trace?   ; commandline.trace?   ; end
    def debug?   ; commandline.debug?   ; end
    def pretend? ; commandline.pretend? ; end

    # Internal status report.
    #
    # Only output if dryrun or trace mode.
    #
    def status(message)
      if pretend? or trace?
        puts message
      end
    end

    # Convenient method to get simple console reply.
    #
    def ask(question, answers=nil)
      print "#{question}"
      print " [#{answers}] " if answers
      until inp = $stdin.gets ; sleep 1 ; end
      inp.strip
    end

    # Ask for a password. (FIXME: only for unix so far)
    #
    def password(prompt=nil)
      msg ||= "Enter Password: "
      inp = ''
      print "#{prompt} "
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

    def print(str)
      super(str) unless quiet?
    end

    def puts(str)
      super(str) unless quiet?
    end

    #
    #
    def printline(left, right='', options={})
      return if quiet?

      separator = options[:seperator] || options[:sep] || ' '
      padding   = options[:padding]   || options[:pad] || 0

      left, right = left.to_s, right.to_s

      left_size  = left.size
      right_size = right.size

      left  = colorize(left)
      right = colorize(right)

      l = padding
      r = -(right_size + padding + 1)

      line = separator * screen_width
      line[l, left_size]  = left  if left_size != 0
      line[r, right_size] = right if right_size != 0

      puts line
    end

    #
    def colorize(text)
      return text unless text.color
      if PLATFORM =~ /win/
        text.to_s
      else
        Clio::ANSICode.send(text.color){ text.to_s }
      end
    end

    #
    def screen_width
      Clio::ConsoleUtils.screen_width
    end

  end

end

