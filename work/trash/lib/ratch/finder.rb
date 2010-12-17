# NOT USED. Expiremental.

module Folio

  require 'pathname'

=begin
  class Pathname

    def glob(*options)
      opts = 0
      options.each do |option|
        case option
        when :nocase
          opts += File::FNM_CASEFOLD
        else
          opts += option
        end
      end

      self.class.glob(to_s, opts).collect{ |f| Pathname.new(f) }
    end

  end
=end

  # This is similar to Rake's FileList.
  #
  class Finder

    #
    attr :patterns
    attr :options

    def <<(pattern)
      patterns << pattern
    end

    #
    def match?(path)
      patterns.find{ |pattern| File.fnmatch?(pattern, path) }
    end

    #
    def match(*options)
      opts = 0
      options.each do
        case options
        when :nocase
          opts += File::FNM_CASEFOLD
        end
      end
      patterns.collect{ |pattern| File.glob(pattern, opts) }.flatten
    end

    def file?(*options)
      match(options).all?{ |f| File.file?(f) }
    end

    def directory?(*options)
      match(options).all?{ |f| File.directory?(f) }
    end

  private

    def initialize(*patterns)
      @patterns = patterns
    end

    def self.[](*patterns)
      new(*patterns)
    end

  end

end

