#--
# TODO: Find way to zip without shelling-out.
#++
module Path

  class Shell

    # Zip
    #
    # TODO: replace with a pure ruby zip library
    #
    def zip(folder, file=nil, options={})
      noop, verbose = *util_options(options)

      raise ArgumentError if folder == '.*'

      file ||= File.basename(File.expand_path(folder)) + '.zip'

      folder = localize(folder)
      file   = localize(file)

      cmd = "zip -rqu #{file} #{folder}"
      puts   cmd if verbose
      system cmd if !noop

      return file
    end

    # Unzip
    #
    def unzip(file, options={})
      noop, verbose = *util_options(options)

      file = localize(file)

      cmd = "unzip #{file}"
      puts   cmd if verbose
      system cmd if !noop
    end

  end

end

