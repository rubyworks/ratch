module Ratch

  # Provides a pure-Ruby method for generating RDocs.
  module RDocUtils

    DEFAULT_RDOC_OPTIONS = {
      :quiet => true
    }

    # RDoc command.
    #
    # :call-seq:
    #   rdoc(file1, file2, ..., :opt1 => val1, ...)
    #
    def rdoc(*files)
      require 'rdoc/rdoc'

      options = Hash===files.last ? files.pop : {}
      options.rekey!(&:to_s)

      options['title'] ||= options.delete('T')

      options['debug']   = options['debug']   #|| debug?
      options['quiet']   = options['quiet']   #|| quiet?
      options['verbose'] = options['verbose'] #|| verbose?

      # apply pom (todo?)
      #options['title'] ||= metadata.title

      options = DEFAULT_RDOC_OPTIONS.merge(options)

      locally do
        rdoc = RDoc::RDoc.new
        opts = options.to_argv + files
        $stderr.puts("rdoc " + opts.join(' ')) if ($VERBOSE || $DEBUG)
        disable_warnings do
          rdoc.document(options.to_argv + files)
        end
      end
    end

    #
    # TODO: Implement ri doc generator.

  end

end

