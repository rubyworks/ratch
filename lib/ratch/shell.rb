require 'path/shell'

module Ratch

  # Ratch shell is a subclass of Path::Shell (see rubyworks/path project).
  # It extends the Path::Shell with commands generally associated with
  # working with Ruby projects and other Ruby-oriented shell activies.
  #
  # Whereever possible a command should call on the underlying tool
  # programmatically rather than shelling out.
  #
  class Shell < Path::Shell

    # load plugins
    PluginManager.find('ratch/shell/*') do |file|
      require file
    end

  end

end

