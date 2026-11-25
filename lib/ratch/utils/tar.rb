require 'ratch/utils/zlib'

module Ratch

  # Utility methods for working with tar archives. They use the tar
  # reader and writer that come with RubyGems, so nothing else is needed.
  #
  # Regular files and directories are archived; links and special files
  # are skipped.
  module TarUtils

    # When included, include ZlibUtils too.
    def self.included(base)
      require 'rubygems/package'
      base.__send__(:include, ZlibUtils)
    end

    #
    def self.extended(base)
      require 'rubygems/package'
      base.extend(ZlibUtils)
    end

    # Archive a folder as FOLDER.tar, or as +file+. Returns the archive's
    # path.
    def tar(folder, file=nil, options={})
      options, file = file, nil if Hash === file
      noop, verbose = *util_options(options)

      file ||= File.basename(localize(folder)) + '.tar'

      $stderr.puts "tar -cf #{file} #{folder}" if verbose

      File.open(localize(file), 'wb'){ |io| tar_pack(folder, io) } unless noop

      path(file)
    end

    # Unpack a tar archive into the working directory. Returns the paths
    # unpacked.
    def untar(file, options={})
      noop, verbose = *util_options(options)

      $stderr.puts "tar -xf #{file}" if verbose

      return [] if noop

      File.open(localize(file), 'rb'){ |io| tar_unpack(io) }
    end

    # Archive a folder as FOLDER.tar.gz, or as +file+. Returns the
    # archive's path.
    def tar_gzip(folder, file=nil, options={})
      options, file = file, nil if Hash === file
      noop, verbose = *util_options(options)

      file ||= File.basename(localize(folder)) + '.tar.gz'

      $stderr.puts "tar -czf #{file} #{folder}" if verbose

      Zlib::GzipWriter.open(localize(file)){ |gz| tar_pack(folder, gz) } unless noop

      path(file)
    end

    alias_method :tar_z, :tar_gzip

    # Unpack a gzipped tar archive into the working directory. Returns
    # the paths unpacked.
    def untar_gzip(file, options={})
      noop, verbose = *util_options(options)

      $stderr.puts "tar -xzf #{file}" if verbose

      return [] if noop

      Zlib::GzipReader.open(localize(file)){ |gz| tar_unpack(gz) }
    end

    alias_method :untar_z, :untar_gzip

  private

    # Write the folder and all in it to +io+ as a tar archive, with paths
    # as given, relative to the working directory.
    def tar_pack(folder, io)
      folder = folder.to_s.chomp('/')
      Gem::Package::TarWriter.new(io) do |tar|
        ([folder] + glob(File.join(folder, '**/*'), File::FNM_DOTMATCH)).uniq.each do |entry|
          next if entry =~ /(\A|\/)\.\.?\z/
          real = localize(entry)
          stat = File.lstat(real)
          if stat.directory?
            tar.mkdir(entry, stat.mode & 0777)
          elsif stat.file?
            tar.add_file_simple(entry, stat.mode & 0777, stat.size) do |out|
              File.open(real, 'rb'){ |f| IO.copy_stream(f, out) }
            end
          end
        end
      end
    end

    # Unpack the tar archive read from +io+ into the working directory.
    # An entry that would land outside it is refused.
    def tar_unpack(io)
      paths = []
      Gem::Package::TarReader.new(io) do |tar|
        tar.each do |entry|
          name = entry.full_name
          dest = File.expand_path(File.join(work.to_s, name))
          unless dest == work.to_s || dest.start_with?(work.to_s + '/')
            raise ArgumentError, "tar entry outside of the directory -- #{name}"
          end
          if entry.directory?
            ::FileUtils.mkdir_p(dest)
          elsif entry.file?
            ::FileUtils.mkdir_p(File.dirname(dest))
            File.open(dest, 'wb'){ |f| IO.copy_stream(entry, f) }
            File.chmod(entry.header.mode & 0777, dest)
          else
            next
          end
          paths << name
        end
      end
      paths
    end

  end

end
