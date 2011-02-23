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

  test :trace? do |options|
    o = Hash[*options]
    sh = Ratch::Shell.new(o)
    sh.trace?
  end

  ok [:trace, true]

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

  ok [:noop, true, :trace, true]
  ok [:dryrun, true]

  no [:noop, true]
  no [:verbose, true]

end
