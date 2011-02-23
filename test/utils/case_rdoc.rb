require 'ratch'

KO.case "Ratch::RDocUtils" do

  def initialize #before :all do
    @shell = Ratch::Shell.new
    @shell.extend(Ratch::RDocUtils)
  end

  setup do
    stage_copy 'fixtures/rdoc_sample'
  end

  test "#rdoc" do
    @shell.rdoc('README.rdoc', 'lib')
    File.directory?('doc') &&
    File.directory?('doc/classes') &&
    File.directory?('doc/files') &&
    File.file?('doc/classes/RDocSample.html')
  end

end

