module FileTest

  if File::ALT_SEPARATOR
    SEPARATOR_PAT = /[#{Regexp.quote File::ALT_SEPARATOR}#{Regexp.quote File::SEPARATOR}]/
  else
    SEPARATOR_PAT = /#{Regexp.quote File::SEPARATOR}/
  end

  ###############
  module_function
  ###############

  # Predicate method for testing whether a path is absolute.
  # It returns +true+ if the pathname begins with a slash.
  def absolute?(path)
    !relative?(path)
  end

  # The opposite of #absolute?
  def relative?(path)
    while r = chop_basename(path.to_s)
      path, basename = r
    end
    path == ''
  end

  # Return a cached list of the PATH environment variable.
  # This is a support method used by #bin?
  def command_paths
    @command_paths ||= ENV['PATH'].split(/[:;]/)
  end

  # Is a file a bin/ executable?
  #
  # TODO: Make more robust. Probably needs to be fixed for Windows.
  def bin?(fname)
    is_bin = command_paths.any? do |f|
      FileTest.exist?(File.join(f, fname))
    end
    #is_bin ? File.basename(fname) : false
    is_bin ? fname : false
  end

  ## Is a file a task?
  #
  #def task?(path)
  #  task = File.dirname($0) + "/#{path}"
  #  task.chomp!('!')
  #  task if FileTest.file?(task) && FileTest.executable?(task)
  #end

  # Is a path considered reasonably "safe"?
  #
  # TODO: Make more robust.
  def safe?(path)
    case path
    when *[ '/', '/*', '/**/*' ]
      return false
    end
    true
  end

  # Chop_basename(path) -> [pre-basename, basename] or nil
  def chop_basename(path)
    base = File.basename(path)
    if /\A#{SEPARATOR_PAT}?\z/ =~ base
      return nil
    else
      return path[0, path.rindex(base)], base
    end
  end
  #private :chop_basename

  # Does the +parent+ contain the +child+?
  def contains?(child, parent=Dir.pwd)
    parent = File.expand_path(parent)
    child = File.expand_path(child)
    child.sub(parent,'') != child
  end

end

