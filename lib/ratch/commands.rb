module Ratch

  # Commands lets system commands be called as if they were methods of
  # a shell:
  #
  #   shell.git 'status'
  #   shell.rdoc '--op', 'doc', 'lib'
  #
  # It is optional. A shell has it when made with the :commands option,
  # or when the module is included in a Shell subclass or used to extend
  # one shell:
  #
  #   shell = Ratch::Shell.new('project', :commands=>true)
  #
  # A method the shell doesn't have is taken as a command only if there
  # is a program of that name on the PATH. Anything else is the
  # NoMethodError it would be without this, so a misspelt method is still
  # caught.
  #
  # The command is run by Shell#sh, so it is run from the shell's
  # directory and follows the shell's mode. See Shell#cmd for the
  # arguments, and for a way to do this without the module.
  module Commands

    #
    def method_missing(name, *args, &block)
      return super if block || !command?(name)
      run_command(name, *args)
    end

    #
    def respond_to_missing?(name, include_private=false)
      command?(name) || super
    end

  private

    # Is there a program of this name on the PATH?
    def command?(name)
      name = name.to_s
      return false unless name =~ /\A[A-Za-z0-9][\w.+-]*\z/
      ENV['PATH'].to_s.split(File::PATH_SEPARATOR).any? do |dir|
        file = File.join(dir, name)
        File.file?(file) && File.executable?(file)
      end
    end

  end

  # What Shell#cmd gives: an object that runs any method called on it as
  # a command of its shell.
  class Commander < BasicObject

    #
    def initialize(shell)
      @shell = shell
    end

    #
    def method_missing(name, *args, &block)
      return super if block
      @shell.__send__(:run_command, name, *args)
    end

    #
    def respond_to_missing?(name, include_private=false)
      true
    end

  end

end
