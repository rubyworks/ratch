class Ratch

  # Methods for utilizing Ruby POM.
  module POM

    def self.included(base)
      require 'pom'
    end

    #
    def project
      @project ||= POM::Project.new
    end

  end

end

