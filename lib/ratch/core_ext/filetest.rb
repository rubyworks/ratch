module FileTest

  module_function

  # The directories of the PATH. Empty if there is none.
  def command_paths
    ENV['PATH'].to_s.split(File::PATH_SEPARATOR)
  end

  # Is there a file of this name in a directory of the PATH? Returns
  # the name if so, and false if not.
  def bin?(fname)
    is_bin = command_paths.any? do |dir|
      FileTest.exist?(File.join(dir, fname.to_s))
    end
    is_bin ? fname : false
  end

end
