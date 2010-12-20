require 'ratch/shell'

KO.case 'Shell' do

  test 'with no path given current working directory is used' do
    sh = Ratch::Shell.new
    sh.work == Pathname.new(Dir.pwd)
  end

  test :quiet? do |options|
    o = Hash[*options]
    sh = Ratch::Shell.new(o)
    sh.quiet?
  end

  ok [:quiet, true]

  test :verbose? do |options|
    o = Hash[*options]
    sh = Ratch::Shell.new(o)
    sh.verbose?
  end

  ok [:verbose, true]

  test :noop? do |options|
    o = Hash[*options]
    sh = Ratch::Shell.new(o)
    sh.noop?
  end

  ok [:noop, true]

  test :dryrun? do |options|
    o = Hash[*options]
    sh = Ratch::Shell.new(o)
    sh.dryrun?
  end

  ok [:noop, true, :verbose, true]
  ok [:dryrun, true]

  no [:noop, true]
  no [:verbose, true]

end
