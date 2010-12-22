module Ratch

  # Utility extensions for working with configuration files.
  #--
  # TODO: Perhaps utilize confectionary gem in future?
  #++
  module ConfigUtils

    #
    def self.included(base)
      require 'yaml'
    end

    def self.extended(base)
      included(base)
    end

    # Load configuration data from a file. Results are cached and an empty
    # Hash is returned if the file is not found.
    #
    # Since they are YAML files, they can optionally end with '.yaml' or '.yml'.
    def configuration(file)
      @configuration ||= {}
      @configuration[file] ||= (
        begin
          configuration!(file)
        rescue LoadError
          Hash.new{ |h,k| h[k] = {} }
        end
      )
    end

    # Load configuration data from a file. The "bang" version will raise an error
    # if file is not found. It also does not cache the results.
    #
    # Since they are YAML files, they can optionally end with '.yaml' or '.yml'.
    def configuration!(file)
      @configuration ||= {}
      patt = file + "{.yml,.yaml,}"
      path = Dir.glob(patt, File::FNM_CASEFOLD).find{ |f| File.file?(f) }
      if path
        # The || {} is in case the file is empty.
        data = YAML::load(File.open(path)) || {}
        @configuration[file] = data
      else
        raise LoadError, "Missing file -- #{path}"
      end
    end

  end

end
