module Ratch

  # XDG module provides some conenience methods for working
  # with the XDG dirtectory standard.
  #
  # FIXME: This module need serious work. The method names are too general
  # and the it probably is easy enough to do without the xdg gem dependency.
  module XDG

    def self.included(base)
      begin
        require 'xdg'
      rescue LoadError
        raise "The Ratch::XDG module requires the `xdg` gem."
      end
    end

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
