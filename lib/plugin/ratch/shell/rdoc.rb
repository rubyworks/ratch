module Ratch

  class Shell

    # RDoc command.
    #
    # :call-seq:
    #   rdoc(file1, file2, ..., :opt1 => val1, ...)
    #
    def rdoc(*files_options)
      require 'rdoc/rdoc'

      options = Hash===options.last ? options.pop : {}
      options.rekey!(&:to_s)

      files = files_options

      options['title'] ||= options.delete('T')

      options['debug']   = options['debug']   || debug?
      options['quiet']   = options['quiet']   || quiet?
      options['verbose'] = options['verbose'] || verbose?

      # apply pom
      options['title'] ||= metadata.title

      # apply defaults
      options = defaults.rdoc.to_h.merge(options)

      locally do
        rdoc = RDoc::RDoc.new
        rdoc.document(options.to_argv + files)
      end
    end

  end

end

