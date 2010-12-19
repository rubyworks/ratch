module Ratch

  #
  module RCov

    # rcov command.
    #
    # :call-seq:
    #   rcov(script1, script2, ..., :opt1 => val1, ...)
    # 
    # NOTE: This command shells out.
    #
    def rcov(*files_options)
      require 'rdoc/rdoc'

      options = Hash===options.last ? options.pop : {}
      options.rekey!(&:to_s)

      files = files_options

      options['output'] ||= options.delete('o')

      #options['debug']   = options['debug']   || debug?
      #options['quiet']   = options['quiet']   || quiet?
      #options['verbose'] = options['verbose'] || verbose?

      options['output'] ||= project.log + 'rcov'

      # apply pom
      #opts = metadata.select('title').merge(opts)

      # apply defaults
      options = defaults.rcov.to_h.merge(options)

      # shell-out
      sh 'rcov' + (options.to_argv + files).join(' ')

      #locally do
      #  rcov = ?
      #  rcov.document(options.to_argv + files)
      #end
    end

  end

end

