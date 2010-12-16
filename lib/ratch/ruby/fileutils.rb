require 'fileutils'

module FileUtils

  ###############
  module_function
  ###############

  # Stage by hard linking included files to a stage directory.
  #
  #   stage_directory   Stage directory.
  #   files             Files to link to stage.
  #
  # TODO: Rename to linkstage or something less likely to name clash?
  # TODO: Add options for :verbose, :noop and :dryrun ?
  #
  def stage(stage_directory, source_directory, files)
    stage_directory, source_directory = stage_directory.to_s, source_directory.to_s
    # Ensure existance of staging area.
    rm_r(stage_directory) if File.directory?(stage_directory)
    mkdir_p(stage_directory)
    # Link files into staging area.
    files.each do |f|
      src  = File.join(source_directory, f)
      file = File.join(stage_directory, f)
      if File.directory?(src)
        mkdir_p(file) unless File.exist?(file)
      else
        fdir = File.dirname(file)
        mkdir_p(fdir) unless File.exist?(fdir)
        unless File.exist?(file) and File.mtime(file) >= File.mtime(src)
          ln(src, file) #safe_ln ?
        end
      end
    end
    return stage_directory
  end

  # Opposite of uptodate?
  #
  def outofdate?(path, *sources)
    #return true unless File.exist?(path)
    ! uptodate?(path, sources.flatten)
  end

  # DEPRECATE
  # Does a path need updating, based on given +sources+?
  # This compares mtimes of give paths. Returns false
  # if the path needs to be updated.
  #
  def out_of_date?(path, *sources)
    return true unless File.exist?(path)

    sources = sources.collect{ |source| Dir.glob(source) }.flatten
    mtimes  = sources.collect{ |file| File.mtime(file) }

    return true if mtimes.empty?  # TODO: This the way to go here?

    File.mtime(path) < mtimes.max
  end

  # An intergrated glob like method that take a set of include globs,
  # exclude globs and ignore globs to produce a collection of paths.
  # 
  # The ignore_globs differ from exclude_globs in that they match by
  # the basename of the path rather than the whole pathname.
  #
  # TODO: Should ignore be based on any portion of the path, not just the basename?
  #
  def amass(include_globs, exclude_globs=[], ignore=[])
    include_files = include_globs.flatten.map{ |g| Dir.glob(g) }.flatten.uniq
    exclude_files = exclude_globs.flatten.map{ |g| Dir.glob(g) }.flatten.uniq

    include_globs = include_globs.map{ |f| File.directory?(f) ? File.join(f, '**/*') : f } # Recursive!
    exclude_globs = exclude_globs.map{ |f| File.directory?(f) ? File.join(f, '**/*') : f } # Recursive!

    include_files = include_globs.flatten.map{ |g| Dir.glob(g) }.flatten.uniq
    exclude_files = exclude_globs.flatten.map{ |g| Dir.glob(g) }.flatten.uniq

    files = include_files - exclude_files

    files = files.reject{ |f| ignore.any?{ |x| File.fnmatch?(x, File.basename(f)) } }

    files
  end

  module Verbose
    public :outofdate?
    #def stage(stage_directory, files, options={})
    #  options[:verbose] = true
    #  FileUtils.stage(stage_directory, files, options={})
    #end
  end

  module NoWrite
    public :outofdate?
    #def stage(stage_directory, files, options={})
    #  options[:noop] = true
    #  FileUtils.stage(stage_directory, files, options={})
    #end
    # Stage by hard linking included files to a stage directory.
    #
    #   stage_directory   Stage directory.
    #   files             Files to link to stage.
    #
    def stage(stage_directory, files)
      return stage_directory  # Don't link to stage if dryrun.
    end
  end

  module DryRun
    public :outofdate?
    #def stage(stage_directory, files, options={})
    #  options[:dryrun] = true
    #  FileUtils.stage(stage_directory, files, options={})
    #end
  end

end

