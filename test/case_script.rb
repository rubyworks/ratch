testcase Ratch::Script do

  # Run a command of Ratch's own, from +dir+, and return its output and status.
  def run_bin(name, dir, *args)
    lib = File.expand_path('lib')
    bin = File.expand_path("bin/#{name}")
    out = IO.popen([RbConfig.ruby, "-I#{lib}", bin, *args, :chdir=>dir, :err=>[:child, :out]]){ |io| io.read }
    [out, $?.exitstatus]
  end

  test "a script is run inside a shell" do
    sample_dir do |dir|
      File.write(File.join(dir, 'foo.ratch'), "@message = read('foo.txt')\nmkdir 'made'\n")
      script = Ratch::Script.new(File.join(dir, 'foo.ratch'), dir)
      script.script_file.assert == File.join(dir, 'foo.ratch')
      script.execute!
      script.instance_variable_get('@message').assert == 'SAMPLE FOO.TXT'
      File.assert.directory?(File.join(dir, 'made'))
    end
  end

  test "$0 is the script while it runs" do
    sample_dir do |dir|
      file = File.join(dir, 'foo.ratch')
      File.write(file, "@zero = $0\n")
      script = Ratch::Script.new(file, dir)
      old = $0
      script.run!
      script.instance_variable_get('@zero').assert == file
      $0.assert == old
    end
  end

  test "#define_method adds a method to the script" do
    sample_dir do |dir|
      file = File.join(dir, 'foo.ratch')
      File.write(file, "define_method(:okay){ 'okay' }\n@said = okay\n")
      script = Ratch::Script.new(file, dir)
      script.execute!
      script.instance_variable_get('@said').assert == 'okay'
    end
  end

  test "the ratch command runs a script in the present directory" do
    sample_dir do |dir|
      File.write(File.join(dir, 'foo.ratch'), "puts glob('*.txt').sort.join(' ')\np arguments\n")
      out, status = run_bin('ratch', dir, 'foo.ratch', 'a', 'b')
      out.assert == "bar.txt foo.txt\n[\"a\", \"b\"]\n"
      status.assert == 0
    end
  end

  test "the ratch command takes the shell's modes as options" do
    sample_dir do |dir|
      File.write(File.join(dir, 'foo.ratch'), "rm 'foo.txt'\n")
      out, status = run_bin('ratch', dir, 'foo.ratch', '--dryrun')
      out.assert == "rm foo.txt\n"
      File.assert.exist?(File.join(dir, 'foo.txt'))
    end
  end

  context "ludo" do

    test "it runs a script found in a directory above, from that directory, with the arguments" do
      sample_dir do |dir|
        File.write(File.join(dir, 'hello'), "#!/bin/sh\necho \"in $(pwd) with $*\"\nexit 3\n")
        File.chmod(0755, File.join(dir, 'hello'))
        out, status = run_bin('ludo', File.join(dir, 'zoo'), 'hello', 'x', 'y')
        out.assert == "in #{dir} with x y\n"
        status.assert == 3
      end
    end

    test "it says so when there is no such script" do
      sample_dir do |dir|
        out, status = run_bin('ludo', dir, 'no-such-script-anywhere')
        out.assert == "ludo: script not found -- no-such-script-anywhere\n"
        status.assert == 1
      end
    end

    test "a file that is not executable is passed over" do
      sample_dir do |dir|
        out, status = run_bin('ludo', File.join(dir, 'zoo'), 'foo.txt')
        status.assert == 1
      end
    end

  end

end
