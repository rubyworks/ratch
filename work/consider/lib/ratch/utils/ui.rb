module Ratch

  module UI

    #
    def yes?(question)
      case ask(question).downcase
      when 'y', 'yes'
        true
      else
        false
      end
    end

    #
    def no?(question)
      case ask(question).downcase
      when 'n', 'no'
        true
      else
        false
      end
    end

    # TODO: Until we have better support for getting input acorss platforms
    # we are using #ask only.
    def password(prompt=nil)
      ask(prompt || "Enter Password: ")
    end

    # Ask for a password. (FIXME: only for unix so far)
    #def password(prompt=nil)
    #  prompt ||= "Enter Password: "
    #  inp = ''
    #  stdout << "#{prompt} "
    #  stdout.flush
    #  begin
    #    #system "stty -echo"
    #    #inp = gets.chomp
    #    until inp = $stdin.gets
    #      sleep 1
    #    end
    #  ensure
    #    #system "stty echo"
    #  end
    #  return inp.chomp
    #end

  end

end
