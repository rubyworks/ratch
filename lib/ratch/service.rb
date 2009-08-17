require 'ratch/dsl'

module Ratch

  # = Service
  #
  # In particular this means creating module for RunModes and FileUtils
  # which uses it, as these are the primary couplings between the batch
  # context and the services that are shared by all.

  class Service < DSL

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

