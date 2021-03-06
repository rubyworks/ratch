require 'ratch/utils/zlib'

module Ratch

  # Utility methods for working with tarballs archives.
  #--
  # TODO: Add compress support ?
  # TODO: Add bzip support ?
  #++
  module TarUtils

    # When included include GZipUtils too.
    def self.included(base)
      #require 'zlib'
      include ZLibUtils
      require 'archive/tar/minitar'
    end

    #
    def self.extended(base)
      included(base)
    end

    # Tar
    def tar(folder, file=nil, options={})
      noop, verbose = *util_options(options)
      file ||= File.basename(File.expand_path(folder)) + '.tar'
      cmd = "tar -cf #{file} #{folder}"
      puts cmd if verbose
      unless noop
        locally do
          gzIO = File.open(file, 'wb')
          Archive::Tar::Minitar.pack(folder, gzIO)
        end
      end
      path(file)
    end

    # Untar
    def untar(file, options={})
      noop, verbose = *util_options(options)
      #file ||= File.basename(File.expand_path(folder)) + '.tar'
      cmd = "untar #{file}"
      puts cmd if verbose
      unless noop
        locally do
          gzIO = File.open(file, 'wb')
          Archive::Tar::Minitar.unpack(gzIO)
        end
      end
      path(file)
    end

    # Tar Gzip
    def tar_gzip(folder, file=nil, options={})
      noop, verbose = *util_options(options)
      file ||= File.basename(File.expand_path(folder)) + '.tar.gz' # '.tgz' which ?
      cmd = "tar --gzip -czf #{file} #{folder}"
      puts cmd if verbose
      unless noop
        locally do #folder, file = localize(folder), localize(file)
          gzIO = Zlib::GzipWriter.new(File.open(file, 'wb'))
          Archive::Tar::Minitar.pack(folder, gzIO)
        end
      end
      path(file)
    end

    alias_method :tar_z, :tar_gzip

    # Untar Gzip
    #
    # FIXME: Write unified untar_gzip function.
    def untar_gzip(file, options={})
      untar(ungzip(file, options), options)
    end

    alias_method :untar_z, :untar_gzip

    #def tgz(folder, file=nil, options={})
    #  file ||= File.basename(File.expand_path(folder)) + '.tgz'
    #  tar_gzip(folder, file, options)
    #end

  end

end

