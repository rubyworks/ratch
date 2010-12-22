require 'ratch'

KO.case "Ratch::RDocUtils" do

  work_location 'rdoc_sample'

  before :all do
    @shell = Ratch::Shell.new
    @shell.extend(Ratch::RDocUtils)
  end

  before :each do
    stage 'fixtures/rdoc_sample'
  end

  test "#rdoc" do
    @shell.rdoc('README.rdoc', 'lib')
    File.directory?('doc') &&
    File.directory?('doc/classes') &&
    File.directory?('doc/files') &&
    File.file?('doc/classes/RDocSample.html')
  end

end

