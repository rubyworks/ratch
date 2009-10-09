module Ratch

  class Shell

    # Create a gzip file.
    #
    def gzip(file, tofile=nil, options={})
      require 'zlib'

      noop, verbose = *util_options(options)

      tofile ||= File.basename(file) + '.gz'

      puts "gzip #{file}" if verbose

      file   = localize(file)
      tofile = localize(tofile)
        
      Zlib::GzipWriter.open(tofile) do |gz|
        gz.write(File.read(file))
      end unless noop

      return tofile
    end

    # Unpack a gzip file.
    #
    def ungzip(file, options={})
      require 'zlib'

      noop, verbose = *util_options(options)

      fname = File.basename(file).chomp(File.extname(file))

      puts "ungzip #{file}" if verbose

      fname = localize(fname)
      file  = localize(file)

      Zlib::GzipReader.open(file) do |gz|
        File.open(fname, 'wb'){ |f| f << gz.read }
      end unless noop

      return fname
    end

  end

end

