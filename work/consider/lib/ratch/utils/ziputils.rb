#require 'zlib'

# = ZipUtils
#
# Function module for compression methods.
#
# TODO: Much of this shells out. It would be best to internalize.
#
module ZipUtils

  COMPRESS_FORMAT = {
    '.tar.gz'  => 'tar_gzip',
    '.tgz'     => 'tar_gzip',
    '.tar.bz2' => 'tar_bzip',
    '.tar.bz'  => 'tar_bzip',
    '.tbz2'    => 'tar_bzip',
    '.tbz'     => 'tar_bzip',
    '.zip'     => 'zip'
  }

  ###############
  module_function
  ###############

  # Compress folder or file based on file extension.
  #
  # Supported extensions are:
  # * .tar.gz
  # * .tgz
  # * .tar.bz2
  # * .zip
  #
  # TODO: support gzip and bzip2 as well.
  #
  def compress(folder, file, options={})
    format = COMPRESS_FORMAT[File.extname(file)]
    if format
      __send__(format, folder, file, options)
    else
      raise ArgumentError, "unknown compression format -- #{format}"
    end
  end

#    # Compress directory.
#    #
#    def compress(format, folder, file=nil, options={})
#      case format.to_s.downcase
#      when 'zip'
#        ziputils.zip(folder, file, options)
#      when 'tgz'
#        ziputils.tgz(folder, file, options)
#      when 'tbz', 'bzip'
#        ziputils.tar_bzip(folder, file, options)
#      else
#        raise ArguementError, "unsupported compression format -- #{format}"
#      end
#    end

  #
  #
  def gzip(file, tofile=nil, option={})
    require 'zlib'
    tofile ||= File.basename(file) + '.gz'
    if options[:dryrun] or options[:verbose]
      puts "gzip #{file}"
    end
    Zlib::GzipWriter.open(tofile) do |gz|
      gz.write(File.read(file))
    end unless options[:dryrun] or options[:noop]
    return File.expand_path(tofile)
  end

  #
  #
  def ungzip(file, options={})
    require 'zlib'
    fname = File.basename(file).chomp(File.extname(file))
    if options[:dryrun] or options[:verbose]
      puts "ungzip #{file}"
    end
    Zlib::GzipReader.open(file) do |gz|
      File.open(fname, 'wb'){ |f| f << gz.read }
    end unless options[:dryrun] or options[:noop]
    return File.expand_path(fname)
  end

  # Bzip
  #
  # NOTE: Does not actually support +tofile+!
  #
  def bzip(file, tofile=nil, option={})
    cmd = "bzip2 #{file}"
    puts   cmd if     options[:dryrun] or options[:verbose]
    system cmd unless options[:dryrun] or options[:noop]
    return File.expand_path(file + '.bz2')
  end

  alias_method :bzip2, :bzip

  #
  #
  def unbzip(file, options={})
    cmd = "unbzip2 #{file}"
    puts   cmd if     options[:dryrun] or options[:verbose]
    system cmd unless options[:dryrun] or options[:noop]
    return File.expand_path(file.chomp(File.extname(file)))
  end

  alias_method :unbzip2, :unbzip

  #
  #
  def tar(folder, file=nil, options={})
    require 'folio/minitar'
    file ||= File.basename(File.expand_path(folder)) + '.tar'
    cmd = "tar -cf #{file} #{folder}"
    puts cmd if options[:verbose] or options[:dryrun]
    unless options[:noop] or options[:dryrun]
      gzIO = File.open(file, 'wb')
      Archive::Tar::Minitar.pack(folder, gzIO)
    end
    return File.expand_path(file)
  end

  #
  #
  def untar(file, options={})
    require 'folio/minitar'
    #file ||= File.basename(File.expand_path(folder)) + '.tar'
    cmd = "untar #{file}"
    puts cmd if options[:verbose] or options[:dryrun]
    unless options[:noop] or options[:dryrun]
      gzIO = File.open(file, 'wb')
      Archive::Tar::Minitar.unpack(gzIO)
    end
    return File.expand_path(file)
  end

  # Tar Gzip
  #
  def tar_gzip(folder, file=nil, options={})
    require 'zlib'
    require 'folio/minitar'
    file ||= File.basename(File.expand_path(folder)) + '.tar.gz' # '.tgz' which ?
    cmd = "tar --gzip -czf #{file} #{folder}"
    puts cmd if options[:verbose] or options[:dryrun]
    unless options[:noop] or options[:dryrun]
      gzIO = Zlib::GzipWriter.new(File.open(file, 'wb'))
      Archive::Tar::Minitar.pack(folder, gzIO)
    end
    return File.expand_path(file)
  end

  alias_method :tar_z, :tar_gzip

  #def tgz(folder, file=nil, options={})
  #  file ||= File.basename(File.expand_path(folder)) + '.tgz'
  #  tar_gzip(folder, file, options)
  #end

  # Untar Gzip
  #
  # TODO: Write unified untar_gzip function.
  def untar_gzip(file, options={})
    untar(ungzip(file, options), options)
  end

  alias_method :untar_z, :untar_gzip

  # Tar Bzip2
  #
  def tar_bzip(folder, file=nil, options={})
    # name of file to create
    file ||= File.basename(File.expand_path(folder)) + '.tar.bz2'
    cmd = "tar --bzip2 -cf #{file} #{folder}"
    puts   cmd if     options[:dryrun] or options[:verbose]
    system cmd unless options[:dryrun] or options[:noop]
    return File.expand_path(file)
  end

  alias_method :tar_bzip2, :tar_bzip

  alias_method :tar_j, :tar_bzip

  # Untar Bzip2
  #
  def untar_bzip(file, options={})
    cmd = "tar --bzip2 -xf #{file}"
    puts   cmd if     options[:dryrun] or options[:verbose]
    system cmd unless options[:dryrun] or options[:noop]
  end

  alias_method :untar_bzip2, :untar_bzip

  alias_method :untar_j, :untar_bzip2

  # Zip
  #
  # TODO: replace with a pure ruby zip library
  #
  def zip(folder, file=nil, options={})
    raise ArgumentError if folder == '.*'
    file ||= File.basename(File.expand_path(folder)) + '.zip'
    cmd = "zip -rqu #{file} #{folder}"
    puts   cmd if     options[:dryrun] or options[:verbose]
    system cmd unless options[:dryrun] or options[:noop]
    return File.expand_path(file)
  end

  # Unzip
  #
  def unzip(file, options={})
    cmd = "unzip #{file}"
    puts   cmd if     options[:dryrun] or options[:verbose]
    system cmd unless options[:dryrun] or options[:noop]
  end

end #module ZipUtils

# Verbose version of ZipUtils.
#
# This is the same as passing :verbose flag to ZipUtils methods.
#
module ZipUtils::Verbose
  module_function

  def compress(format_extension, folder, file=nil, options={})
    options[:verbose] = true
    ZipUtils.tar_gzip(format_extension, folder, file, options)
  end

  def gzip(file, tofile=nil, options={})
    options[:verbose] = true
    ZipUtils.gzip(file, options)
  end

  def ungzip(file, options={})
    options[:verbose] = true
    ZipUtils.ungzip(file, options)
  end

  def bzip(file, tofile=nil, options={})
    options[:verbose] = true
    ZipUtils.bzip(file, options)
  end

  alias_method :bzip2, :bzip

  def unbzip(file, options={})
    options[:verbose] = true
    ZipUtils.unbzip(file, options)
  end

  alias_method :unbzip2, :unbzip

  def tar(folder, file=nil, options={})
    options[:verbose] = true
    ZipUtils.tar(folder, file, options)
  end

  def untar(file, options={})
    options[:verbose] = true
    ZipUtils.untar(file, options)
  end

  def tar_gzip(folder, file=nil, options={})
    options[:verbose] = true
    ZipUtils.tar_gzip(folder, file, options)
  end

  def untar_gzip(file, options={})
    options[:verbose] = true
    ZipUtils.untar_gzip(file, options)
  end

  def tar_bzip(folder, file=nil, options={})
    options[:verbose] = true
    ZipUtils.untar_bzip2(folder, file, options)
  end

  alias_method :tar_bzip2, :tar_bzip

  def untar_bzip(file, options={})
    options[:verbose] = true
    ZipUtils.untar_bzip2(file, options)
  end

  alias_method :untar_bzip2, :untar_bzip

  def zip(folder, file=nil, options={})
    options[:verbose] = true
    ZipUtils.unzip(folder, file, options)
  end

  def unzip(file, options={})
    options[:verbose] = true
    ZipUtils.unzip(file, options)
  end
end

# NoWrite Version of ZipUtils.
#
# This is the same as passing :noop flag to ZipUtils methods.
#
module ZipUtils::NoWrite
  module_function

  def compress(format_extension, folder, file=nil, options={})
    options[:noop] = true
    ZipUtils.tar_gzip(format_extension, folder, file, options)
  end

  def gzip(file, options={})
    options[:noop] = true
    ZipUtils.gzip(file, options)
  end

  def ungzip(file, options={})
    options[:noop] = true
    ZipUtils.ungzip(file, options)
  end

  def bzip(file, options={})
    options[:noop] = true
    ZipUtils.bzip(file, options)
  end

  alias_method :bzip2, :bzip

  def unbzip2(file, options={})
    options[:noop] = true
    ZipUtils.unbzip2(file, options)
  end

  alias_method :unbzip, :unbzip2

  def tar(folder, file=nil, options={})
    options[:noop] = true
    ZipUtils.tar(folder, file, options)
  end

  def untar(file, options={})
    options[:noop] = true
    ZipUtils.untar(file, options)
  end

  def tar_gzip(folder, file=nil, options={})
    options[:noop] = true
    ZipUtils.tar_gzip(folder, file, options)
  end

  def untar_gzip(file, options={})
    options[:noop] = true
    ZipUtils.untar_gzip(file, options)
  end

  def tar_bzip(folder, file=nil, options={})
    options[:noop] = true
    ZipUtils.untar_bzip(folder, file, options)
  end

  alias_method :tar_bzip2, :tar_bzip

  def untar_bzip(file, options={})
    options[:noop] = true
    ZipUtils.untar_bzip(file, options)
  end

  alias_method :untar_bzip2, :untar_bzip

  def zip(folder, file=nil, options={})
    options[:noop] = true
    ZipUtils.unzip(folder, file, options)
  end

  def unzip(file, options={})
    options[:noop] = true
    ZipUtils.unzip(file, options)
  end
end

# Dry-run verions of ZipUtils.
#
# This is the same as passing the :dryrun flag to ZipUtils.
# Which is also equivalent to passing :noop and :verbose together.

module ZipUtils::DryRun
  module_function

  def compress(format_extension, folder, file=nil, options={})
    options[:dryrun] = true
    ZipUtils.tar_gzip(format_extension, folder, file, options)
  end

  def gzip(file, options={})
    options[:dryrun] = true
    ZipUtils.gzip(file, options)
  end

  def ungzip(file, options={})
    options[:dryrun] = true
    ZipUtils.ungzip(file, options)
  end

  def bzip2(file, options={})
    options[:dryrun] = true
    ZipUtils.bzip2(file, options)
  end

  alias_method :bzip, :bzip2

  def unbzip2(file, options={})
    options[:dryrun] = true
    ZipUtils.unbzip2(file, options)
  end

  alias_method :unbzip, :unbzip2

  def tar(folder, file=nil, options={})
    options[:dryrun] = true
    ZipUtils.tar(folder, file, options)
  end

  def untar(file, options={})
    options[:dryrun] = true
    ZipUtils.untar(file, options)
  end

  def tar_gzip(folder, file=nil, options={})
    options[:dryrun] = true
    ZipUtils.tar_gzip(folder, file, options)
  end

  def untar_gzip(file, options={})
    options[:dryrun] = true
    ZipUtils.untar_gzip(file, options)
  end

  def tar_bzip(folder, file=nil, options={})
    options[:dryrun] = true
    ZipUtils.untar_bzip(folder, file, options)
  end

  alias_method :tar_bzip2, :tar_bzip

  def untar_bzip(file, options={})
    options[:dryrun] = true
    ZipUtils.untar_bzip(file, options)
  end

  alias_method :untar_bzip2, :untar_bzip

  def zip(folder, file=nil, options={})
    options[:dryrun] = true
    ZipUtils.unzip(folder, file, options)
  end

  def unzip(file, options={})
    options[:dryrun] = true
    ZipUtils.unzip(file, options)
  end
end



# OLD VERSION
#   #
#   # DryRun version of ZipUtils.
#   #
#
#   module DryRun
#     module_function
#
#     def compress( format, folder, to_file=nil )
#       send(FORMAT_TO_COMPRESS[format], folder, to_file)
#     end
#
#     # Tar Gzip
#
#     def tar_gzip( folder, to_file=nil )
#       to_file ||= File.basename(File.expand_path(folder)) + '.tar.gz'
#       puts "tar --gzip -czf #{to_file} #{folder}"
#     end
#
#     # Untar Gzip
#
#     def untar_gzip( file )
#       puts "tar --gzip -xzf #{file}"
#     end
#
#     # Tar Bzip2
#
#     def tar_bzip( folder, to_file=nil )
#       puts "tar --bzip2 -cf #{to_file} #{folder}"
#     end
#     alias_method :tar_bz2, :tar_bzip
#
#     # Untar Bzip2
#
#     def untar_bzip( file )
#       puts "tar --bzip2 -xf #{file}"
#     end
#     alias_method :untar_bz2, :untar_bzip
#
#     # Zip
#
#     def zip( folder, to_file=nil )
#       puts "zip -cf #{to_file} #{folder}"
#     end
#
#     # Unzip
#
#     def unzip( file )
#       puts "zip -xf #{file}"
#     end
#
#   end

=begin
  #############
  # ZipUtils  #
  #############

  # Compress directory to file. Format is determined
  # by file extension.
  #def compress(folder, file, options={})
  #  #folder = localize(file)
  #  #file   = localize(file)
  #  locally do
  #    doc(ziputils.compress(folder, file, options))
  #  end
  #end

  #
  def gzip(file, tofile=nil, options={})
    #file   = localize(file)
    #tofile = localize(tofile) if tofile
    locally do
      file(ziputils.gzip(file, tofile, options))
    end
  end

  #
  def bzip(file, tofile=nil, options={})
    #file   = localize(file)
    #tofile = localize(tofile) if tofile
    locally do
      doc(ziputils.bzip(file, tofile, options))
    end
  end

  # Create a zip file of a directory.
  def zip(folder, file=nil, options={})
    #folder = localize(folder)
    #file   = localize(file)
    locally do
      doc(ziputils.zip(folder, file, options))
    end
  end

  #
  def tar(folder, file=nil, options={})
    #folder = localize(folder)
    #file   = localize(file)
    locally do
      doc(ziputils.tar_gzip(folder, file, options))
    end
  end

  # Create a tgz file of a directory.
  def tar_gzip(folder, file=nil, options={})
    #folder = localize(folder)
    #file   = localize(file)
    locally do
      doc(ziputils.tar_gzip(folder, file, options))
    end
  end
  alias_method :tgz, :tar_gzip

  # Create a tar.bz2 file of a directory.
  def tar_bzip2(folder, file=nil, options={})
    #folder = localize(folder)
    #file   = localize(file)
    locally do
      doc(ziputils.tar_bzip2(folder, file, options))
    end
  end

  def ungzip(file, options)
    #file   = localize(file)
    locally do
      ziputils.ungzip(file, options)
    end
  end

  def unbzip2(file, options)
    #file   = localize(file)
    locally do
      ziputils.unbzip2(file, options)
    end
  end

  def unzip(file, options)
    #file   = localize(file)
    locally do
      ziputils.unzip(file, options)
    end
  end

  def untar(file, options)
    #file   = localize(file)
    locally do
      ziputils.untar(file, options)
    end
  end

  def untar_gzip(file, options)
    #file   = localize(file)
    locally do
      ziputils.untar_gzip(file, options)
    end
  end

  def untar_bzip2(file, options)
    #file   = localize(file)
    locally do
      ziputils.untar_bzip2(file, options)
    end
  end

  # Returns ZipUtils module based on mode.
  def ziputils
    if dryrun?
      ::ZipUtils::DryRun
    elsif noop?
      ::ZipUtils::Noop
    elsif trace?
      ::ZipUtils::Verbose
    else
      ::ZipUtils
    end
  end
=end

