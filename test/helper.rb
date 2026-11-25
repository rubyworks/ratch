require 'assay/ae'
require 'rbconfig'
require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'ratch'

module Spectrum::World

  # Make a sample directory, run the block with its path, and remove it.
  #
  #   foo.txt
  #   bar.txt
  #   zoo/
  #   zoo/one.txt
  #   zoo/two.txt
  #
  def sample_dir
    Dir.mktmpdir('ratch') do |dir|
      dir = File.realpath(dir)
      File.write(File.join(dir, 'foo.txt'), 'SAMPLE FOO.TXT')
      File.write(File.join(dir, 'bar.txt'), 'SAMPLE BAR.TXT')
      Dir.mkdir(File.join(dir, 'zoo'))
      File.write(File.join(dir, 'zoo/one.txt'), 'ONE')
      File.write(File.join(dir, 'zoo/two.txt'), 'TWO')
      yield dir
    end
  end

  # What a block writes to standard error.
  def capture_stderr
    old, $stderr = $stderr, StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old
  end

  def pathnames(*names)
    names.map{ |n| Pathname.new(n) }
  end

end
