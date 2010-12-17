require 'fileutils'
require 'digest/md5'

module FileTest
  module_function

  BUF_SIZE = 1024*1024

  # Are two files identical? This compares size and then checksum.
  def identical?(file1, file2)
    size(file1) == size(file2) && md5(file1) == md5(file2)
  end

  # Return an md5 checkum. If a directory is given, will
  # return a nested array of md5 checksums for all entries.

  def md5(path)
    if File.directory?(path)
      md5_list = []
      crt_dir = Dir.new(path)
      crt_dir.each do |file_name|
        next if file_name == '.' || file_name == '..'
        md5_list << md5("#{crt_dir.path}#{file_name}")
      end
      md5_list
    else
      hasher = Digest::MD5.new
      open(path, "r") do |io|
        counter = 0
        while (!io.eof)
          readBuf = io.readpartial(BUF_SIZE)
          counter+=1
          #putc '.' if ((counter+=1) % 3 == 0)
          hasher.update(readBuf)
        end
      end
      return hasher.hexdigest
    end
  end

  # Show diff of two files.

  def diff(file1, file2)
    `diff #{file1} #{file2}`.strip
  end

end
