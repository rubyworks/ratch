begin
  require 'xdg'
rescue LoadError
  require 'ratch/vendor/xdg'
end

module Ratch

  class Shell

    # Look up a config file.
    def config(path)
      file(XDG.xdg_config_file(path))
    end

    # Look up a data file.
    def data(path)
      file(XDG.xdg_data_file(path))
    end

    # Look up a cache file.
    def cache(path)
      file(XDG.xdg_cache_file(path))
    end

    # Return a enumertor of system config directories.
    def root_config() #_directories
      XDG.xdg_config_dirs.to_enum(:each){ |f| dir(f) }
    end

    # Return a enumertor of system data directories.
    def root_data() #_directories
      XDG.xdg_data_dirs.to_enum(:each){ |f| dir(f) }
    end

    # Return the home config directory.
    def home_config
      dir(XDG.xdg_config_home)
    end

    # Return the home data directory.
    def home_data
      dir(XDG.xdg_data_home)
    end

    # Return the home cache directory.
    def home_cache
      dir(XDG.xdg_cache_home)
    end

    # Return the work config directory.
    def work_config
      dir(XDG.xdg_config_work)
    end

    # Return the work cache directory.
    def work_cache
      dir(XDG.xdg_cache_work)
    end

  end

end
