module Ratch

  # The XDG utility module provides access ot the XDG library functions.
  # This module requires the `xdg` gem.
  #
  # This module simply maps the #xdg method to the XDG function module.
  #
  # NOTE: This module is non-essential since one can just use
  # the XDG module directly, however we want to encourage the
  # use XDG, so it's been provided to encourage that in the context
  # of a Ratch script.
  #
  module XDGUtils

    def self.included(base)
      begin
        require 'xdg'
      rescue
        $stderr << "The `xdg` gem is needed to use the XDGUtils module."
        exit -1
      end
    end

    def self.extended(base)
      included(base)
    end
    
    # Simple access to XDG function module.
    #
    #   xdg.config.home  #=> "~/.config"
    #
    def xdg
      XDG
    end
 
  end

end

