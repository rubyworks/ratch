require 'ratch/plugin'

module Ratchet
  extend self

  #
  class Plugin < Ratch::Plugin

    def self.context
      @context ||= DSL.new
    end

    # Not sure if we should be cacheing plugins,
    # but it's worth a shot.
    def self.new(options,&block)
      options = options.merge(block.to_h) if block
      @plugins[options] ||= super(context, options)
    end

  end

end

