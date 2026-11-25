testcase "Utilities" do

  class UtilShell < Ratch::Shell
    include Ratch::ConfigUtils
    include Ratch::ZlibUtils
    include Ratch::TarUtils
    include Ratch::RDocUtils
    include Ratch::EmailUtils
  end

  context Ratch::ZlibUtils do

    test "#gzip and #ungzip" do
      sample_dir do |dir|
        shell = UtilShell.new(dir)
        shell.gzip('foo.txt')
        shell.assert.file?('foo.txt.gz')
        shell.rm('foo.txt')
        shell.ungzip('foo.txt.gz')
        shell.read('foo.txt').assert == 'SAMPLE FOO.TXT'
      end
    end

    test "#gzip to a named file, under a directory" do
      sample_dir do |dir|
        shell = UtilShell.new(dir)
        shell.gzip('zoo/one.txt', 'one.gz')
        Zlib::GzipReader.open(File.join(dir, 'one.gz')){ |gz| gz.read }.assert == 'ONE'
        shell.gzip('zoo/two.txt')
        shell.assert.file?('zoo/two.txt.gz')
      end
    end

    test "noop makes nothing" do
      sample_dir do |dir|
        UtilShell.new(dir, :noop=>true).gzip('foo.txt')
        File.refute.exist?(File.join(dir, 'foo.txt.gz'))
        UtilShell.new(dir).gzip('foo.txt', :noop=>true)
        File.refute.exist?(File.join(dir, 'foo.txt.gz'))
      end
    end

  end

  context Ratch::TarUtils do

    test "#tar and #untar" do
      sample_dir do |dir|
        shell = UtilShell.new(dir)
        File.chmod(0755, File.join(dir, 'zoo/one.txt'))
        shell.tar('zoo').assert == Pathname.new(dir) + 'zoo.tar'
        shell.rm_r('zoo')
        shell.untar('zoo.tar').sort.assert == %w{zoo zoo/one.txt zoo/two.txt}
        shell.read('zoo/two.txt').assert == 'TWO'
        (File.stat(File.join(dir, 'zoo/one.txt')).mode & 0777).assert == 0755
      end
    end

    test "the archive is one the tar command reads" do
      sample_dir do |dir|
        shell = UtilShell.new(dir)
        shell.tar_gzip('zoo')
        out = IO.popen(['tar', '-tzf', File.join(dir, 'zoo.tar.gz')]){ |io| io.read }
        out.split("\n").map{ |l| l.chomp('/') }.sort.assert == %w{zoo zoo/one.txt zoo/two.txt}
      end
    end

    test "#tar_gzip and #untar_gzip" do
      sample_dir do |dir|
        shell = UtilShell.new(dir)
        shell.tar_gzip('zoo', 'z.tgz')
        shell.rm_r('zoo')
        shell.untar_gzip('z.tgz')
        shell.read('zoo/one.txt').assert == 'ONE'
      end
    end

    test "an entry that would land outside the directory is refused" do
      sample_dir do |dir|
        File.open(File.join(dir, 'bad.tar'), 'wb') do |io|
          Gem::Package::TarWriter.new(io){ |tar| tar.add_file_simple('../escaped.txt', 0644, 1){ |o| o.write('x') } }
        end
        ArgumentError.assert.raised?{ UtilShell.new(dir).untar('bad.tar') }
        File.refute.exist?(File.join(File.dirname(dir), 'escaped.txt'))
      end
    end

    test "noop makes nothing" do
      sample_dir do |dir|
        UtilShell.new(dir, :noop=>true).tar('zoo')
        File.refute.exist?(File.join(dir, 'zoo.tar'))
      end
    end

  end

  context Ratch::ConfigUtils do

    test "#configuration loads a YAML file, with or without its extension" do
      sample_dir do |dir|
        File.write(File.join(dir, 'settings.yml'), "name: ratch\n")
        shell = UtilShell.new(dir)
        shell.configuration('settings').assert == {'name'=>'ratch'}
        shell.configuration('settings.yml').assert == {'name'=>'ratch'}
      end
    end

    test "a missing file gives an empty configuration, or an error from the bang method" do
      sample_dir do |dir|
        shell = UtilShell.new(dir)
        shell.configuration('nothing').assert == {}
        LoadError.assert.raised?{ shell.configuration!('nothing') }
      end
    end

  end

  context Ratch::RDocUtils do

    test "#rdoc documents files into a directory" do
      sample_dir do |dir|
        File.write(File.join(dir, 'thing.rb'), "# A thing.\nclass Thing; end\n")
        UtilShell.new(dir).rdoc('thing.rb', :op=>'doc', :title=>'Things')
        File.assert.file?(File.join(dir, 'doc/Thing.html'))
        File.read(File.join(dir, 'doc/index.html')).assert.include?('Things')
      end
    end

  end

  context Ratch::EmailUtils do

    test "an Emailer takes its settings from options" do
      mail = Ratch::Emailer.new(:server=>'mail.example.com', :from=>'a@example.com', :to=>'b@example.com',
                                :subject=>'Hi', :message=>'Hello', :secure=>true)
      mail.port.assert == 465
      mail.account.assert == 'a@example.com'
      mail.login.assert == :plain
      mail.domain.assert == 'mail.example.com'
    end

    test "a missing field is an error" do
      mail = Ratch::Emailer.new(:server=>'mail.example.com', :from=>'a@example.com')
      ArgumentError.assert.raised?{ mail.email }
    end

    test "a failed delivery returns the error" do
      mail = Ratch::Emailer.new(:server=>'127.0.0.1', :port=>9, :from=>'a@example.com', :to=>'b@example.com',
                                :subject=>'Hi', :message=>'Hello')
      mail.email.assert.is_a?(StandardError)
    end

  end

  context "core extensions" do

    test "#to_list" do
      'a:b,c'.to_list.assert == %w{a b c}
      %w{a b}.to_list.assert == %w{a b}
      nil.to_list.assert == []
    end

    test "#to_argv and #to_console" do
      args = ['file', {:op=>'my doc', :q=>true, :no=>false, :I=>%w{a b}}]
      args.to_argv.assert == ['--op=my doc', '-q', '-Ia', '-Ib', 'file']
      args.size.assert == 2
      Shellwords.split(args.to_console).assert == args.to_argv
      ['file', {:quiet=>true}].to_console.assert == '--quiet file'
    end

  end

end
