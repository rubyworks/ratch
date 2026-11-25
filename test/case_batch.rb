testcase Ratch::Batch do

  # Run the block from inside the sample directory.
  def in_sample
    sample_dir do |dir|
      Dir.chdir(dir){ yield dir }
    end
  end

  context "the list" do

    test "files are taken by pattern under the batch's directory" do
      in_sample do
        batch = Ratch::Batch.new('.', '*.txt')
        batch.local.assert == Pathname.new('.')
        batch.to_a.sort.assert == pathnames('bar.txt', 'foo.txt')
        batch.list.sort.assert == %w{bar.txt foo.txt}
        batch.file_list.assert.is_a?(Ratch::FileList)
        batch.size.assert == 2
      end
    end

    test "a batch of another directory lists full paths, and #entries the local ones" do
      sample_dir do |dir|
        batch = Ratch::Batch.new(dir, '**/*.txt')
        batch.list.sort.assert == %w{bar.txt foo.txt zoo/one.txt zoo/two.txt}.map{ |f| File.join(dir, f) }
        batch.entries.sort.assert == pathnames('bar.txt', 'foo.txt', 'zoo/one.txt', 'zoo/two.txt')
      end
    end

    test "it is enumerable, over Pathnames" do
      in_sample do
        batch = Ratch::Batch.new('.', '*.txt')
        batch.each{ |pn| pn.assert.is_a?(Pathname) }
        batch.map{ |pn| pn.extname }.assert == %w{.txt .txt}
      end
    end

    test "#file! and #directory! narrow the list" do
      in_sample do
        batch = Ratch::Batch.new('.', '*')
        batch.file!
        batch.list.sort.assert == %w{bar.txt foo.txt}

        batch = Ratch::Batch.new('.', '*')
        batch.directory!
        batch.list.assert == %w{zoo}

        batch = Ratch::Batch.new('.', '*')
        batch.select!{ |f| f =~ /^f/ }
        batch.list.assert == %w{foo.txt}
      end
    end

    test "backup files are left out, unless all are wanted" do
      in_sample do
        File.write('foo.txt~', '')
        File.write('foo.bak', '')
        Ratch::Batch.new('.', '*').list.sort.assert == %w{bar.txt foo.txt zoo}
        Ratch::Batch.all('.', '*').list.sort.assert == %w{bar.txt foo.bak foo.txt foo.txt~ zoo}
      end
    end

  end

  context "file tests" do

    test "a test holds if it holds for every file" do
      in_sample do
        batch = Ratch::Batch.new('.', '*.txt')
        batch.assert.file?
        batch.assert.exist?
        batch.assert.exists?
        batch.assert.readable?
        batch.refute.directory?
        Ratch::Batch.new('.', '*').refute.file?
        Ratch::Batch.new('.', 'zoo').assert.directory?
      end
    end

    test "#byte_size adds up" do
      in_sample do
        Ratch::Batch.new('.', '*.txt').byte_size.assert == 28
      end
    end

    test "#outofdate? and #uptodate?" do
      in_sample do
        old = Time.now - 100
        File.utime(old, old, 'foo.txt')
        batch = Ratch::Batch.new('.', 'zoo/*')
        batch.assert.outofdate?('foo.txt')
        batch.refute.uptodate?('foo.txt')
        batch.assert.outofdate?('nothing')
        File.utime(old - 100, old - 100, 'zoo/one.txt', 'zoo/two.txt')
        batch.refute.outofdate?('foo.txt')
        batch.assert.uptodate?('foo.txt')
      end
    end

  end

  context "file operations" do

    test "#cp and #mv into a directory" do
      in_sample do
        Dir.mkdir('out')
        Ratch::Batch.new('.', '*.txt').cp('out')
        Dir.children('out').sort.assert == %w{bar.txt foo.txt}
        Ratch::Batch.new('.', 'zoo/*').mv('out')
        Dir.children('out').sort.assert == %w{bar.txt foo.txt one.txt two.txt}
        Dir.children('zoo').assert == []
      end
    end

    test "the destination is taken from the batch's directory" do
      sample_dir do |dir|
        Ratch::Batch.new(dir, '*.txt').cp('zoo')
        Dir.children(File.join(dir, 'zoo')).sort.assert == %w{bar.txt foo.txt one.txt two.txt}
      end
    end

    test "#rm, #touch and #chmod" do
      in_sample do
        Ratch::Batch.new('.', '*.txt').chmod(0600)
        (File.stat('foo.txt').mode & 0777).assert == 0600
        old = Time.now - 100
        File.utime(old, old, 'foo.txt')
        Ratch::Batch.new('.', '*.txt').touch
        (File.mtime('foo.txt') > old).assert == true
        Ratch::Batch.new('.', '*.txt').rm
        Dir.children('.').assert == %w{zoo}
        Ratch::Batch.new('.', 'zoo').rm_r
        Dir.children('.').assert == []
      end
    end

    test "#mkdir_p makes a directory for every entry" do
      in_sample do
        Ratch::Batch.new('.', 'a/b', 'c').mkdir_p
        File.assert.directory?('a/b')
        File.assert.directory?('c')
        Errno::EEXIST.assert.raised?{ Ratch::Batch.new('.', 'foo.txt').mkdir_p }
      end
    end

    test "#ln_s and #install" do
      in_sample do
        Dir.mkdir('out')
        Ratch::Batch.new('.', 'zoo/*').ln_s('out')
        File.assert.symlink?('out/one.txt')
        Dir.mkdir('bin')
        Ratch::Batch.new('.', '*.txt').install('bin', 0755)
        (File.stat('bin/foo.txt').mode & 0777).assert == 0755
      end
    end

    test "#stage hard links each file at its local path" do
      sample_dir do |dir|
        Ratch::Batch.new(dir, '**/*.txt').stage('stage')
        Dir.glob('**/*', base: File.join(dir, 'stage')).sort.assert == %w{bar.txt foo.txt zoo zoo/one.txt zoo/two.txt}
        File.assert.identical?(File.join(dir, 'foo.txt'), File.join(dir, 'stage/foo.txt'))
      end
    end

    test "#rename moves each file to the name the block gives" do
      in_sample do
        batch = Ratch::Batch.new('.', '*.txt')
        batch.rename{ |f| f.sub('.txt', '.text') }
        Dir.children('.').sort.assert == %w{bar.text foo.text zoo}
        batch.list.sort.assert == %w{bar.text foo.text}
      end
    end

    test "#rename leaves alone a file the block gives nil for" do
      in_sample do
        Ratch::Batch.new('.', '*.txt').rename{ |f| f =~ /foo/ ? 'FOO' : nil }
        Dir.children('.').sort.assert == %w{FOO bar.txt zoo}
      end
    end

    test "#map_cp refuses to copy over an existing file" do
      in_sample do
        Errno::EEXIST.assert.raised? do
          Ratch::Batch.new('.', 'foo.txt').map_cp{ |f| 'bar.txt' }
        end
        File.read('bar.txt').assert == 'SAMPLE BAR.TXT'
        Ratch::Batch.new('.', 'foo.txt').map_cp(:force=>true){ |f| 'bar.txt' }
        File.read('bar.txt').assert == 'SAMPLE FOO.TXT'
      end
    end

  end

  context "modes" do

    test "noop changes nothing" do
      in_sample do
        batch = Ratch::Batch.new('.', '*.txt', :noop=>true)
        batch.assert.noop?
        batch.rm
        batch.mv('zoo')
        batch.rename{ |f| f + '.x' }
        Dir.children('.').sort.assert == %w{bar.txt foo.txt zoo}
      end
    end

    test "dryrun reports and does nothing" do
      in_sample do
        batch = Ratch::Batch.new('.', '*.txt', :dryrun=>true)
        batch.assert.dryrun?
        out = capture_stderr{ batch.rm }
        out.assert.include?('rm ')
        out.assert.include?('foo.txt')
        File.assert.exist?('foo.txt')
      end
    end

    test "a mode can be given for one command" do
      in_sample do
        Ratch::Batch.new('.', '*.txt').rm(:noop=>true)
        File.assert.exist?('foo.txt')
      end
    end

  end

end

testcase Ratch::FileList do

  test "it is lazy, and resolves its patterns when read" do
    sample_dir do |dir|
      Dir.chdir(dir) do
        list = Ratch::FileList['*.txt']
        File.write('new.txt', '')
        list.sort.assert == %w{bar.txt foo.txt new.txt}
      end
    end
  end

  test "#include and #exclude" do
    sample_dir do |dir|
      Dir.chdir(dir) do
        list = Ratch::FileList.new('*.txt')
        list.include('zoo/*')
        list.exclude(/one/)
        list.exclude('bar.*')
        list.sort.assert == %w{foo.txt zoo/two.txt}
      end
    end
  end

  test "#ext and #sub" do
    Ratch::FileList['a.c', 'b.c'].ext('o').assert == %w{a.o b.o}
    Ratch::FileList['a.c', 'b.c'].sub(/\.c$/, '.h').assert == %w{a.h b.h}
  end

  test "it compares with an Array" do
    (Ratch::FileList['a', 'b'] == %w{a b}).assert == true
    Ratch::FileList['a', 'b'].to_a.assert.is_a?(Array)
  end

end
