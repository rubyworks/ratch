require 'ratch/script'

module Ratch

  # = Service

  class Service < Script

    private

    #
    def initialize(options=nil)
      options ||= {}

      initialize_defaults

      options.each do |k, v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end
    end

    #
    def initialize_defaults
    end

  end

end

