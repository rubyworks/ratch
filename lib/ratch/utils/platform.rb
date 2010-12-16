# TODO: Do this without facets platform or improve facets platform (see Zucker)
require 'facets/platform'

module Ratch

  # Methods for determining platform.
  module Platform

    # Current platform.
    def current_platform
      Platform.local.to_s
    end

    #
    def windows?

    end

  end

end

