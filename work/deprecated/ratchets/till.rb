module Ratchets

  #
  def till(options)
    Till.new(options).generate
  end

  # = Till Code Generator Service
  #
  class Till < Plugin

    def valid?
      begin
        require 'till'
        true
      rescue LoadError
        false
      end
    end

    #
    def safe?; @safe; end

    #
    def generate(options={})
      options ||= {}

      dir = nil # defaults to curent directory

      options[:noop]  = noop?  #safe? #dryrun?
      options[:debug] = debug?
      options[:quiet] = quiet?
      options[:force] = force?

      tiller = Till::Tiller.new(dir, options)
      tiller.till
    end

  end

end

