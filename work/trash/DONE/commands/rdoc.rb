module Ratch

  class Shell

    #
    def rdoc(*files_options)
      options = Hash===options.last ? options.pop : {}
      options.rekey!

      options[:debug]   ||= debug?
      options[:quiet]   ||= quiet?
      options[:verbose] ||= verbose?

      files = files_options

      locally do
        rdoc = RDoc::RDoc.new
        rdoc.document(options.to_argv + files)
      end
    end

  end

end

