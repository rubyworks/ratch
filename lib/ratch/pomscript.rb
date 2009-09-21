require 'ratch/script'
require 'pom/project'

module Ratch

  #
  class POMScript < Script

    attr :project

    #
    def initialize(options={})
      @project ||= POM::Project.new
      options[:path] = @project.root
      super(options)
    end

    #
    def metadata
      project.metadata
    end

    # Access a log by name.
    def logfile(name)
      @logfile ||= {}
      @logfile[name.to_s] ||= (
        Log.new(self, project.log + name.to_s)
      )
    end

    # to be deprecated
    alias_method :log, :logfile

  end

end
