class Ratch

  # Methods for utilizing Ruby POM.
  module POM

    def preinitialize
      require 'pom/project'
    end

    #
    def project
      @project ||= POM::Project.new
    end

  end

end

