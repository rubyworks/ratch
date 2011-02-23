require 'ratch'

KO.case "Ratch::POMUtils" do

  def initialize
    stage_copy 'fixtures/pom_sample'

    @shell = Ratch::Shell.new
    @shell.extend(Ratch::POMUtils)
  end

  test :project do
    @shell.project.is_a?(::POM::Project)
  end

end

