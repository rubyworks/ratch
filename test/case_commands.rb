testcase "Commands" do

  # A sample directory with a program of its own on the PATH, which
  # writes its arguments, one to a line, to the file `said`.
  def with_program
    sample_dir do |dir|
      bin = File.join(dir, 'bin')
      Dir.mkdir(bin)
      File.write(File.join(bin, 'ratch-say'), "#!/bin/sh\nfor a in \"$@\"; do echo \"$a\"; done > said\n")
      File.chmod(0755, File.join(bin, 'ratch-say'))
      old = ENV['PATH']
      begin
        ENV['PATH'] = "#{bin}#{File::PATH_SEPARATOR}#{old}"
        yield dir
      ensure
        ENV['PATH'] = old
      end
    end
  end

  context "Shell#ruby" do

    test "it runs the present Ruby from the shell's directory" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, 'zoo')
        shell.ruby('-e', 'File.write("out.txt", [RUBY_VERSION, Dir.pwd].join(" "))').assert == true
        shell.read('out.txt').assert == "#{RUBY_VERSION} #{File.join(dir, 'zoo')}"
        shell.ruby('-e', 'exit 1').assert == false
      end
    end

    test "a single string is the rest of a command line" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.write('s.rb', 'File.write("out.txt", ARGV.join("+"))')
        shell.ruby('s.rb a b').assert == true
        shell.read('out.txt').assert == 'a+b'
      end
    end

    test "it follows the shell's mode" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :dryrun=>true)
        out = capture_stderr{ shell.ruby('-e', 'File.write("out.txt", "x")') }
        out.assert.include?(RbConfig.ruby)
        File.refute.exist?(File.join(dir, 'out.txt'))
      end
    end

  end

  context "Shell#cmd" do

    test "a method called on it is run as a command, with its arguments as they are" do
      with_program do |dir|
        shell = Ratch::Shell.new(dir)
        shell.cmd.__send__('ratch-say', 'one two', 'three').assert == true
        shell.read('said').assert == "one two\nthree\n"
      end
    end

    test "a final Hash becomes options" do
      with_program do |dir|
        shell = Ratch::Shell.new(dir)
        shell.cmd.__send__('ratch-say', 'lib', :op=>'my doc', :q=>true)
        shell.read('said').assert == "--op=my doc\n-q\nlib\n"
      end
    end

    test "a single string is a command line for the system shell" do
      with_program do |dir|
        shell = Ratch::Shell.new(dir)
        shell.cmd.__send__('ratch-say', '-l *.txt')
        shell.read('said').assert == "-l\nbar.txt\nfoo.txt\n"
      end
    end

    test "it reports failure, and a command that doesn't exist" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :quiet=>true)
        shell.cmd.false.assert == false
        shell.cmd.no_such_command_anywhere.assert.nil?
      end
    end

    test "it follows the shell's mode" do
      with_program do |dir|
        shell = Ratch::Shell.new(dir, :dryrun=>true)
        out = capture_stderr{ shell.cmd.__send__('ratch-say', 'a', 'b') }
        out.assert == "ratch-say a b\n"
        File.refute.exist?(File.join(dir, 'said'))
      end
    end

  end

  context Ratch::Commands do

    test "a shell doesn't have it unless asked" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        NoMethodError.assert.raised?{ shell.true }
        shell.refute.respond_to?(:true)
      end
    end

    test "with the :commands option, a program on the PATH is a method" do
      with_program do |dir|
        shell = Ratch::Shell.new(dir, :commands=>true)
        shell.assert.respond_to?('ratch-say')
        shell.send('ratch-say', 'a', 'b').assert == true
        shell.read('said').assert == "a\nb\n"
        shell.true.assert == true
        shell.false.assert == false
      end
    end

    test "a name that is not a program is still no method" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :commands=>true)
        NoMethodError.assert.raised?{ shell.no_such_command_anywhere }
        NoMethodError.assert.raised?{ shell.mkdri('x') }
        shell.refute.respond_to?(:no_such_command_anywhere)
      end
    end

    test "the shell's own methods come first" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :commands=>true, :noop=>true)
        shell.touch('new.txt')
        shell.pwd.assert == dir
        File.refute.exist?(File.join(dir, 'new.txt'))
      end
    end

    test "a sub-shell has it too" do
      sample_dir do |dir|
        ((Ratch::Shell.new(dir, :commands=>true) / 'zoo').true).assert == true
        NoMethodError.assert.raised?{ (Ratch::Shell.new(dir) / 'zoo').true }
      end
    end

    test "it can be included in a subclass" do
      sample_dir do |dir|
        klass = Class.new(Ratch::Shell){ include Ratch::Commands }
        klass.new(dir).true.assert == true
      end
    end

    test "a script run with --commands has it" do
      with_program do |dir|
        File.write(File.join(dir, 'foo.ratch'), "send('ratch-say', 'from', 'script')\n")
        lib = File.expand_path('lib')
        bin = File.expand_path('bin/ratch')
        IO.popen([RbConfig.ruby, "-I#{lib}", bin, 'foo.ratch', '--commands', :chdir=>dir, :err=>[:child, :out]]){ |io| io.read }.assert == ''
        File.read(File.join(dir, 'said')).assert == "from\nscript\n"
      end
    end

  end

  context "core extensions" do

    test "Array#to_list drops nils" do
      ['a', nil, 'b'].to_list.assert == %w{a b}
    end

    test "#to_yamlfrag is YAML without the document marks" do
      ({'a'=>1}).to_yamlfrag.assert == 'a: 1'
      'text'.to_yamlfrag.assert == 'text'
      [1, 2].to_yamlfrag.assert == "- 1\n- 2"
    end

    test "FileTest.bin? finds a program on the PATH, and survives having none" do
      with_program do |dir|
        FileTest.bin?('ratch-say').assert == 'ratch-say'
        FileTest.bin?('no_such_command_anywhere').assert == false
        old = ENV.delete('PATH')
        begin
          FileTest.bin?('ratch-say').assert == false
        ensure
          ENV['PATH'] = old
        end
      end
    end

  end

end
