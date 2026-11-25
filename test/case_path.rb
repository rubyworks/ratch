testcase Ratch::Path do

  test "a shell's paths are Paths, equal to the Pathnames of the same path" do
    sample_dir do |dir|
      shell = Ratch::Shell.new(dir)
      [shell.path('foo.txt'), shell.file('foo.txt'), shell.dir('zoo'), shell.work, shell.parent, shell.home, shell.root].each do |path|
        path.assert.is_a?(Ratch::Path)
        path.assert.is_a?(Pathname)
        path.shell.assert.equal?(shell)
      end
      shell.path('foo.txt').assert == Pathname.new(dir) + 'foo.txt'
      (Pathname.new(dir) + 'foo.txt').assert == shell.path('foo.txt')
      shell.path('foo.txt').read.assert == 'SAMPLE FOO.TXT'
    end
  end

  test "it changes the file system as a Pathname does" do
    sample_dir do |dir|
      shell = Ratch::Shell.new(dir)
      shell.path('a/b').mkpath
      shell.path('a/b/t.txt').write('T')
      shell.path('a/b/t.txt').append('U')
      shell.path('a/b/t.txt').rename(File.join(dir, 'a/u.txt'))
      shell.read('a/u.txt').assert == 'TU'
      shell.path('zoo').rmtree
      shell.path('foo.txt').delete
      Dir.children(dir).sort.assert == %w{a bar.txt}
    end
  end

  test "in noop mode it changes nothing" do
    sample_dir do |dir|
      shell = Ratch::Shell.new(dir, :noop=>true)
      out = capture_stderr do
        shell.path('zoo').rmtree
        shell.path('new').mkpath
        shell.path('foo.txt').delete
        shell.path('foo.txt').write('CHANGED')
        shell.path('foo.txt').append('MORE')
        shell.path('bar.txt').rename(File.join(dir, 'baz.txt'))
        shell.path('bar.txt').chmod(0600)
      end
      out.assert == ''
      Dir.children(dir).sort.assert == %w{bar.txt foo.txt zoo}
      File.read(File.join(dir, 'foo.txt')).assert == 'SAMPLE FOO.TXT'
      Dir.children(File.join(dir, 'zoo')).sort.assert == %w{one.txt two.txt}
    end
  end

  test "in dryrun mode it reports and changes nothing" do
    sample_dir do |dir|
      shell = Ratch::Shell.new(dir, :dryrun=>true)
      out = capture_stderr do
        shell.path('zoo').rmtree
        shell.path('foo.txt').write('SECRET')
        shell.path('foo.txt').chmod(0600)
      end
      out.assert == "rmtree #{dir}/zoo\nwrite #{dir}/foo.txt\nchmod #{dir}/foo.txt #{0600}\n"
      File.assert.directory?(File.join(dir, 'zoo'))
    end
  end

  test "in trace mode it reports and does it" do
    sample_dir do |dir|
      shell = Ratch::Shell.new(dir, :trace=>true)
      out = capture_stderr{ shell.path('foo.txt').delete }
      out.assert == "delete #{dir}/foo.txt\n"
      File.refute.exist?(File.join(dir, 'foo.txt'))
    end
  end

  test "derived paths keep to the same shell" do
    sample_dir do |dir|
      shell = Ratch::Shell.new(dir, :noop=>true)
      zoo   = shell.path('zoo')
      [zoo + 'one.txt', zoo / 'one.txt', zoo.join('one.txt'), zoo.parent, zoo.dirname,
       zoo.expand_path, zoo.realpath, zoo.sub('zoo', 'foo.txt'), *zoo.children].each do |path|
        path.assert.is_a?(Ratch::Path)
        path.shell.assert.equal?(shell)
      end
      zoo.children.each{ |child| child.delete }
      (zoo + 'one.txt').delete
      zoo.each_child{ |child| child.delete }
      zoo.parent.join('foo.txt').delete
      Dir.children(File.join(dir, 'zoo')).sort.assert == %w{one.txt two.txt}
      File.assert.exist?(File.join(dir, 'foo.txt'))
    end
  end

  test "the mode is the shell's at the time" do
    sample_dir do |dir|
      shell = Ratch::Shell.new(dir)
      path  = shell.path('foo.txt')
      path.refute.noop?
      path.refute.trace?
      Ratch::Shell.new(dir, :dryrun=>true).path('foo.txt').assert.noop?
      Ratch::Shell.new(dir, :dryrun=>true).path('foo.txt').assert.trace?
    end
  end

  test "without a shell it is a Pathname" do
    sample_dir do |dir|
      path = Ratch::Path.new(File.join(dir, 'foo.txt'))
      path.refute.noop?
      path.delete
      File.refute.exist?(File.join(dir, 'foo.txt'))
    end
  end

end
