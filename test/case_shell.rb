testcase Ratch::Shell do

  context "location" do

    test "with no path the present working directory is used" do
      Ratch::Shell.new.work.assert == Pathname.new(Dir.pwd)
    end

    test "a path can be given in parts" do
      sample_dir do |dir|
        Ratch::Shell.new(dir, 'zoo').work.assert == Pathname.new(dir) + 'zoo'
      end
    end

    test "a path that is not a directory is refused" do
      Ratch::FileNotFound.assert.raised? do
        Ratch::Shell.new('not_a_path')
      end
    end

    test "the process's working directory is left alone" do
      sample_dir do |dir|
        here = Dir.pwd
        shell = Ratch::Shell.new(dir)
        shell.touch('new.txt')
        shell.cd('zoo')
        Dir.pwd.assert == here
        shell.pwd.assert == File.join(dir, 'zoo')
      end
    end

    test "#parent, #home and #root" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, 'zoo')
        shell.parent.assert == Pathname.new(dir)
        shell.home.assert == Pathname.new(File.expand_path('~'))
        shell.root.assert == Pathname.new('/')
      end
    end

    test "#path, #file and #dir" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.path('nothing').assert == Pathname.new(dir) + 'nothing'
        shell.file('foo.txt').assert == Pathname.new(dir) + 'foo.txt'
        shell.dir('zoo').assert == Pathname.new(dir) + 'zoo'
        Ratch::FileNotFound.assert.raised?{ shell.file('zoo') }
        Ratch::FileNotFound.assert.raised?{ shell.dir('foo.txt') }
      end
    end

    test "#/ gives a shell at a sub-directory, in the same mode" do
      sample_dir do |dir|
        zoo = Ratch::Shell.new(dir, :noop=>true) / 'zoo'
        zoo.assert.is_a?(Ratch::Shell)
        zoo.pwd.assert == File.join(dir, 'zoo')
        zoo.assert.noop?
      end
    end

    test "#cd moves the shell" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.cd('zoo')
        shell.glob('*').sort.assert == %w{one.txt two.txt}
        shell.cd('..')
        shell.pwd.assert == dir
      end
    end

    test "#cd with a block moves the shell, and the process, for the block only" do
      sample_dir do |dir|
        here  = Dir.pwd
        shell = Ratch::Shell.new(dir)
        seen  = nil
        shell.cd('zoo') do
          seen = [shell.pwd, Dir.pwd]
        end
        seen.assert == [File.join(dir, 'zoo')] * 2
        shell.pwd.assert == dir
        Dir.pwd.assert == here
      end
    end

    test "#cd to a missing directory is refused" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        Ratch::FileNotFound.assert.raised?{ shell.cd('nowhere') }
        shell.pwd.assert == dir
      end
    end

  end

  context "modes" do

    test "the options" do
      Ratch::Shell.new(:quiet=>true).assert.quiet?
      Ratch::Shell.new(:noop=>true).assert.noop?
      Ratch::Shell.new(:nowrite=>true).assert.noop?
      Ratch::Shell.new(:trace=>true).assert.trace?
      Ratch::Shell.new(:verbose=>true).assert.trace?
      Ratch::Shell.new('noop'=>true).assert.noop?
      Ratch::Shell.new.refute.noop?
      Ratch::Shell.new.refute.trace?
    end

    test "dryrun is noop and trace together" do
      shell = Ratch::Shell.new(:dryrun=>true)
      shell.assert.noop?
      shell.assert.trace?
      shell.assert.dryrun?
      Ratch::Shell.new(:noop=>true, :trace=>true).assert.dryrun?
      Ratch::Shell.new(:noop=>true).refute.dryrun?
    end

    test "noop changes nothing" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :noop=>true)
        out = capture_stderr do
          shell.rm('foo.txt')
          shell.rm_r('zoo')
          shell.mkdir('new')
          shell.write('bar.txt', 'CHANGED')
          shell.append('bar.txt', 'MORE')
          shell.mv('bar.txt', 'baz.txt')
          shell.sh('touch made-by-sh')
        end
        out.assert == ''
        Dir.children(dir).sort.assert == %w{bar.txt foo.txt zoo}
        File.read(File.join(dir, 'bar.txt')).assert == 'SAMPLE BAR.TXT'
      end
    end

    test "trace reports each step and does it" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :trace=>true)
        out = capture_stderr do
          shell.rm('foo.txt')
          shell.sh('true')
        end
        out.assert.include?('rm ')
        out.assert.include?('foo.txt')
        out.assert.include?("true\n")
        File.refute.exist?(File.join(dir, 'foo.txt'))
      end
    end

    test "dryrun reports each step and does nothing" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :dryrun=>true)
        out = capture_stderr{ shell.rm_r('zoo') }
        out.assert.include?('rm -r')
        File.assert.directory?(File.join(dir, 'zoo'))
      end
    end

    test "a mode can be given for one command" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.rm('foo.txt', :noop=>true)
        File.assert.exist?(File.join(dir, 'foo.txt'))
        out = capture_stderr{ shell.rm('foo.txt', :dryrun=>true) }
        out.assert.include?('rm ')
        File.assert.exist?(File.join(dir, 'foo.txt'))
      end
    end

  end

  context "equality" do

    test "#== goes by class and working path" do
      Ratch::Shell.new('.').assert == Ratch::Shell.new('.')
      Ratch::Shell.new('.').refute == Ratch::Shell.new('..')
      Ratch::Shell.new('.').refute == '.'
    end

    test "#eql? also wants the same noop" do
      a = Ratch::Shell.new('.', :noop=>true)
      a.assert.eql?(Ratch::Shell.new('.', :noop=>true))
      a.refute.eql?(Ratch::Shell.new('.', :noop=>false))
      ({a => 1}[Ratch::Shell.new('.', :noop=>true)]).assert == 1
    end

  end

  context "listing" do

    test "#entries is Dir.entries as Pathnames" do
      sample_dir do |dir|
        Ratch::Shell.new(dir).entries.sort.assert == pathnames('.', '..', 'bar.txt', 'foo.txt', 'zoo')
      end
    end

    test "#file_entries and #directory_entries" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.file_entries.sort.assert == pathnames('bar.txt', 'foo.txt')
        shell.directory_entries.sort.assert == pathnames('.', '..', 'zoo')
        shell.dir_entries.sort.assert == pathnames('.', '..', 'zoo')
      end
    end

    test "#pathnames, #files and #directories leave out the dot paths" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.pathnames.sort.assert == pathnames('bar.txt', 'foo.txt', 'zoo')
        shell.files.sort.assert == pathnames('bar.txt', 'foo.txt')
        shell.directories.assert == pathnames('zoo')
        shell.folders.assert == pathnames('zoo')
      end
    end

    test "listing goes by the shell's directory, not the process's" do
      sample_dir do |dir|
        (Ratch::Shell.new(dir) / 'zoo').files.sort.assert == pathnames('one.txt', 'two.txt')
      end
    end

    test "#glob gives paths relative to the shell" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.glob('*').sort.assert == %w{bar.txt foo.txt zoo}
        shell.glob('zoo/*', '*.txt').sort.assert == %w{bar.txt foo.txt zoo/one.txt zoo/two.txt}
        shell.glob('**/ONE.TXT', File::FNM_CASEFOLD).assert == [] unless File.exist?(File.join(dir, 'FOO.TXT'))
        shell.glob(File.join(dir, '*.txt')).sort.assert == [File.join(dir, 'bar.txt'), File.join(dir, 'foo.txt')]
      end
    end

    test "#glob takes a block" do
      sample_dir do |dir|
        seen = []
        Ratch::Shell.new(dir).glob('*.txt'){ |f| seen << f }
        seen.sort.assert == %w{bar.txt foo.txt}
      end
    end

    test "#amass includes, excludes and ignores" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.amass(['zoo']).sort.assert == %w{zoo zoo/one.txt zoo/two.txt}
        shell.amass(['*.txt', 'zoo'], ['bar.txt'], ['two.*']).sort.assert == %w{foo.txt zoo zoo/one.txt}
      end
    end

  end

  context "file tests" do

    test "the FileTest methods" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.assert.exist?('foo.txt')
        shell.assert.exists?('foo.txt')
        shell.refute.exist?('nothing')
        shell.assert.file?('foo.txt')
        shell.refute.directory?('foo.txt')
        shell.assert.directory?('zoo')
        shell.assert.dir?('zoo')
        shell.assert.readable?('foo.txt')
        shell.refute.symlink?('foo.txt')
        shell.refute.zero?('foo.txt')
        shell.size('foo.txt').assert == 14
        shell.assert.absolute?('/tmp')
        shell.assert.relative?('tmp')
      end
    end

    test "#identical? and #cmp" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.cp('foo.txt', 'copy.txt')
        shell.ln('foo.txt', 'link.txt')
        shell.assert.identical?('foo.txt', 'link.txt')
        shell.refute.identical?('foo.txt', 'copy.txt')
        shell.assert.cmp('foo.txt', 'copy.txt')
        shell.refute.cmp('foo.txt', 'bar.txt')
      end
    end

    test "#uptodate? and #outofdate?" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.mtime('foo.txt', Time.now - 100)
        shell.assert.outofdate?('foo.txt', 'zoo/*')
        shell.refute.outofdate?('bar.txt', 'foo.txt')
        shell.assert.outofdate?('nothing', 'foo.txt')
        shell.assert.uptodate?('bar.txt', 'foo.txt')
        shell.refute.uptodate?('foo.txt', 'bar.txt')
      end
    end

  end

  context "reading and writing" do

    test "#read, #write and #append" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.read('foo.txt').assert == 'SAMPLE FOO.TXT'
        shell.write('baz.txt', 'BAZ TEXT')
        shell.read('baz.txt').assert == 'BAZ TEXT'
        shell.append('baz.txt', ' 2')
        File.read(File.join(dir, 'baz.txt')).assert == 'BAZ TEXT 2'
      end
    end

    test "#mtime and #atime get and set" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        time  = Time.at(1_000_000_000)
        shell.mtime('foo.txt', time)
        shell.mtime('foo.txt').assert == time
        shell.atime('foo.txt', time + 60)
        shell.atime('foo.txt').assert == time + 60
        shell.mtime('foo.txt').assert == time
        shell.mtime('foo.txt', time + 5, :noop=>true)
        shell.mtime('foo.txt').assert == time
      end
    end

  end

  context "file operations" do

    test "making and removing" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.mkdir('a')
        shell.mkdir_p('b/c/d')
        shell.touch('b/c/d/t.txt')
        shell.touch(['x.txt', 'y.txt'])
        shell.assert.file?('b/c/d/t.txt')
        shell.assert.file?('y.txt')
        shell.rmdir('a')
        shell.rm(['x.txt', 'y.txt'])
        shell.rm_f('nothing')
        shell.rm_r('b')
        shell.rm_rf('zoo')
        Dir.children(dir).sort.assert == %w{bar.txt foo.txt}
      end
    end

    test "copying, moving and linking" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.cp('foo.txt', 'zoo')
        shell.cp_r('zoo', 'zoo2')
        shell.mv('bar.txt', 'baz.txt')
        shell.mv(['foo.txt', 'baz.txt'], 'zoo2')
        shell.ln_s('zoo/one.txt', 'one')
        shell.ln_sf('zoo/two.txt', 'one')
        shell.glob('zoo2/*').sort.assert == %w{zoo2/baz.txt zoo2/foo.txt zoo2/one.txt zoo2/two.txt}
        shell.assert.symlink?('one')
        shell.read('one').assert == 'TWO'
        Dir.children(dir).sort.assert == %w{one zoo zoo2}
      end
    end

    test "#install and #chmod" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.install('foo.txt', 'zoo/foo', 0755)
        (File.stat(File.join(dir, 'zoo/foo')).mode & 0777).assert == 0755
        shell.install('foo.txt', 'zoo/foo2', :mode=>0600)
        (File.stat(File.join(dir, 'zoo/foo2')).mode & 0777).assert == 0600
        shell.chmod(0640, 'foo.txt')
        (File.stat(File.join(dir, 'foo.txt')).mode & 0777).assert == 0640
        shell.chmod_r(0700, 'zoo')
        (File.stat(File.join(dir, 'zoo/one.txt')).mode & 0777).assert == 0700
      end
    end

    test "#stage hard links files into a fresh directory" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.mkdir_p('stage/old')
        shell.stage('stage', %w{foo.txt zoo/one.txt})
        shell.glob('stage/**/*').sort.assert == %w{stage/foo.txt stage/zoo stage/zoo/one.txt}
        shell.assert.identical?('foo.txt', 'stage/foo.txt')
      end
    end

  end

  context "commands" do

    test "#sh runs from the shell's directory and says whether it worked" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, 'zoo')
        shell.sh('pwd > where.txt').assert == true
        shell.read('where.txt').strip.assert == File.join(dir, 'zoo')
        shell.sh('false').assert == false
      end
    end

    test "#sh takes a command in parts" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir)
        shell.sh('touch', 'a b.txt').assert == true
        shell.assert.file?('a b.txt')
      end
    end

    test "#sh in quiet mode drops the output" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :quiet=>true)
        out = IO.popen([RbConfig.ruby, '-Ilib', '-rratch/shell', '-e',
          "Ratch::Shell.new(#{dir.inspect}, :quiet=>true).sh('echo LOUD; echo LOUDER >&2')",
          :err=>[:child, :out]]){ |io| io.read }
        out.assert == ''
        shell.assert.quiet?
      end
    end

    test "#system runs even in noop mode" do
      sample_dir do |dir|
        shell = Ratch::Shell.new(dir, :noop=>true)
        shell.system('touch made.txt').assert == true
        shell.assert.file?('made.txt')
      end
    end

    test "#batch gives a Batch of the shell's files, in its mode" do
      sample_dir do |dir|
        batch = Ratch::Shell.new(dir, :noop=>true).batch('*.txt')
        batch.assert.is_a?(Ratch::Batch)
        batch.entries.map(&:to_s).sort.assert == %w{bar.txt foo.txt}
        batch.assert.noop?
      end
    end

  end

end
