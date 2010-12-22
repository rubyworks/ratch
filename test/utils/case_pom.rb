require 'ratch'

KO.case "Ratch::POMUtils" do

  work_location 'pom_sample'

  before :all do
    stage 'fixtures/pom_sample'

    @shell = Ratch::Shell.new
    @shell.extend(Ratch::POMUtils)
  end

  test :project do
    @shell.project.is_a?(::POM::Project)
  end

end

