require 'ratch/core_ext'
require 'ratch/file_list'

module Ratch

  # Proccess a list of files in batch.
  #
  # The Batch interface mimics the Shell class in most respects.
  #
  # TODO: Should FileList use Pathname, or only in Batch?
  class Batch
    include Enumerable

    # A batch of the files matching +patterns+ under the present
    # directory.
    def self.[](*patterns)
      new('.', *patterns)
    end

    # Like #new, but without the usual exclusions (version control
    # directories, backup and core files).
    def self.all(local, *patterns)
      options = (Hash === patterns.last ? patterns.pop.dup : {})
      new(local, *patterns, options.merge(:all=>true))
    end

    # New batch of the files matching +patterns+, which are relative to
    # the directory +local+. A final Hash gives options: :noop, :verbose
    # (or :trace) and :dryrun, as for Shell, and :all to leave nothing out.
    def initialize(local, *patterns)
      @local   = Pathname.new(local.to_s)
      @options = {}
      (Hash === patterns.last ? patterns.pop : {}).each{ |k, v| @options[k.to_sym] = v }

      @file_list = @options[:all] ? FileList.all : FileList.new

      patterns.flatten.each do |pattern|
        pattern = pattern.to_s
        if @local == Pathname.new('.') || FileTest.absolute?(pattern)
          @file_list.add(pattern)
        else
          @file_list.add(File.join(@local.to_s, pattern))
        end
      end
    end

    #
    attr :local

    # Returns the the underlying FileList object.
    def file_list
      @file_list
    end

    # Iterate over pathnames.
    def each(&block)
      @file_list.each{ |file| block.call(Pathname.new(file)) }
    end

    # Returns the Integer size of the list of files.
    def size
      @file_list.size
    end

    # Return the list of files as Pathname objects.
    def to_a
      @file_list.map{ |file| Pathname.new(file) }
    end

    # Return the list of files as Pathname objects.
    alias_method :pathnames, :to_a

    # Returns the list of files as Strings, rather than Pathname objects.
    def list
      @file_list.to_a
    end
    alias_method :filenames, :list

    # Returns an Array of file paths relative to +local+.
    def entries
      map{ |entry| entry.sub(local.to_s+'/','') }
    end

    # Limit list to files.
    def file!
      @file_list = @file_list.select{ |f| File.file?(f) }
    end

    # Limit list to directories.
    def directory!
      @file_list = @file_list.select{ |f| File.directory?(f) }
    end

    # Limit list to selection block.
    def select!(&block)
      #@file_list = FileList.all(*to_a.select{ |f| block.call(f) })
      @file_list = @file_list.select{ |f| block.call(f) }
    end

    #############
    # FileTest  #
    #############

    # This is called #size in FileTest but must be renamed to 
    # avoid the clash with the Enumerable mixin.
    def byte_size
      inject(0){ |sum, path| sum + FileTest.size(path) }
    end
 
    # An alias for #byte_size.
    alias_method :size?, :byte_size

    def directory?  ; all?{ |path| FileTest.directory?(path)  } ; end
    def symlink?    ; all?{ |path| FileTest.symlink?(path)    } ; end
    def readable?   ; all?{ |path| FileTest.readable?(path)   } ; end
    def chardev?    ; all?{ |path| FileTest.chardev?(path)    } ; end
    def exist?      ; all?{ |path| FileTest.exist?(path)      } ; end
    def exists?     ; all?{ |path| FileTest.exist?(path)      } ; end
    def zero?       ; all?{ |path| FileTest.zero?(path)       } ; end
    def pipe?       ; all?{ |path| FileTest.pipe?(path)       } ; end
    def file?       ; all?{ |path| FileTest.file?(path)       } ; end
    def sticky?     ; all?{ |path| FileTest.sticky?(path)     } ; end
    def blockdev?   ; all?{ |path| FileTest.blockdev?(path)   } ; end
    def grpowned?   ; all?{ |path| FileTest.grpowned?(path)   } ; end
    def setgid?     ; all?{ |path| FileTest.setgid?(path)     } ; end
    def setuid?     ; all?{ |path| FileTest.setuid?(path)     } ; end
    def socket?     ; all?{ |path| FileTest.socket?(path)     } ; end
    def owned?      ; all?{ |path| FileTest.owned?(path)      } ; end
    def writable?   ; all?{ |path| FileTest.writable?(path)   } ; end
    def executable? ; all?{ |path| FileTest.executable?(path) } ; end
    def safe?       ; all?{ |path| FileTest.safe?(path)       } ; end

    # TODO: Will this work since all paths are localized?
    def relative?   ; all?{ |path| FileTest.relative?(path)   } ; end
    def absolute?   ; all?{ |path| FileTest.absolute?(path)   } ; end

    def writable_real?   ; all?{ |path| FileTest.writable_real?(path)   } ; end
    def executable_real? ; all?{ |path| FileTest.executable_real?(path) } ; end
    def readable_real?   ; all?{ |path| FileTest.readable_real?(path)   } ; end

    alias_method :dir?, :directory?

    def identical?(other)
      all?{ |path| FileTest.identical?(path, other) }
    end

    # TODO: Really?
    alias_method :compare_file, :identical?
    alias_method :cmp, :identical?


    #############
    # FileUtils #
    #############

    # Low-level Methods Omitted
    # -------------------------
    # getwd           -> pwd
    # compare_file    -> cmp
    # remove_file     -> rm
    # copy_file       -> cp
    # remove_dir      -> rmdir
    # safe_unlink     -> rm_f
    # makedirs        -> mkdir_p
    # rmtree          -> rm_rf
    # copy_stream
    # remove_entry
    # copy_entry
    # remove_entry_secure
    # compare_stream

    # Present working directory.
    # TODO: Does this make sense?
    def pwd
      @local
    end

    # Make a directory for every entry.
    def mkdir(options={})
      list.each do |dir|
        if File.exist?(dir)
          raise Errno::EEXIST, "File exists - #{dir}"
        end
      end
      list.map{ |dir| fu(:mkdir, options, dir){ |opts| ::FileUtils.mkdir(dir, **opts) } }
    end

    # Make a directory for every entry.
    def mkdir_p(options={})
      list.each do |dir|
        if File.exist?(dir) && !File.directory?(dir)
          raise Errno::EEXIST, "File exists - #{dir}"
        end
      end
      list.map{ |dir| fu(:mkdir_p, options, dir){ |opts| ::FileUtils.mkdir_p(dir, **opts) } }
    end
    alias_method :mkpath, :mkdir_p

    # Remove every directory.
    def rmdir(options={})
      list.map{ |dir| fu(:rmdir, options, dir){ |opts| ::FileUtils.rmdir(dir, **opts) } }
    end

    # ln(list, destdir, options={})
    def ln(dir, options={})
      fu(:ln, options, list, dir){ |opts| ::FileUtils.ln(list, localize(dir), **opts) }
    end
    alias_method :link, :ln

    # ln_s(list, destdir, options={})
    def ln_s(dir, options={})
      fu(:ln_s, options, list, dir){ |opts| ::FileUtils.ln_s(list, localize(dir), **opts) }
    end
    alias_method :symlink, :ln_s

    def ln_sf(dir, options={})
      fu(:ln_sf, options, list, dir){ |opts| ::FileUtils.ln_sf(list, localize(dir), **opts) }
    end

    # cp(list, dir, options={})
    def cp(dir, options={})
      #src  = list.to_a
      #dest = localize(dest)
      fu(:cp, options, list, dir){ |opts| ::FileUtils.cp(list, localize(dir), **opts) }
    end
    alias_method :copy, :cp

    # cp_r(list, dir, options={})
    def cp_r(dir, options={})
      #src  = list.to_a
      #dest = localize(dest)
      fu(:cp_r, options, list, dir){ |opts| ::FileUtils.cp_r(list, localize(dir), **opts) }
    end

    # mv(list, dir, options={})
    def mv(dir, options={})
      #src  = list.to_a
      #dest = localize(dest)
      fu(:mv, options, list, dir){ |opts| ::FileUtils.mv(list, localize(dir), **opts) }
    end
    alias_method :move, :mv

    #
    def rm(options={})
      fu(:rm, options, list){ |opts| ::FileUtils.rm(list, **opts) }
    end

    # Alias for #rm.
    alias_method :remove, :rm

    # Remove, recursively removing the contents of directories.
    def rm_r(options={})
      fu(:rm_r, options, list){ |opts| ::FileUtils.rm_r(list, **opts) }
    end

    # Remove, with force option.
    def rm_f(options={})
      fu(:rm_f, options, list){ |opts| ::FileUtils.rm_f(list, **opts) }
    end

    # Remove with force option, recursively removing the contents of directories.
    def rm_rf(options={})
      fu(:rm_rf, options, list){ |opts| ::FileUtils.rm_rf(list, **opts) }
    end

    # Install files to a directory with given mode. Unlike #cp, this will
    # not copy the file if an up-to-date copy already exists.
    def install(dir, mode, options={})
      #dest = localize(dest)
      fu(:install, options.merge(:mode=>mode), list, dir){ |opts| ::FileUtils.install(list, localize(dir), **opts) }
    end

    # Change mode of files.
    def chmod(mode, options={})
      fu(:chmod, options, mode, list){ |opts| ::FileUtils.chmod(mode, list, **opts) }
    end

    # Change mode of files, following directories recursively.
    def chmod_r(mode, options={})
      fu(:chmod_R, options, mode, list){ |opts| ::FileUtils.chmod_R(mode, list, **opts) }
    end
    #alias_method :chmod_R, :chmod_r

    # Change owner of files.
    def chown(user, group, options={})
      fu(:chown, options, user, group, list){ |opts| ::FileUtils.chown(user, group, list, **opts) }
    end

    # Change owner of files, following directories recursively.
    def chown_r(user, group, options={})
      fu(:chown_R, options, user, group, list){ |opts| ::FileUtils.chown_R(user, group, list, **opts) }
    end
    #alias_method :chown_R, :chown_r

    # Touch each file.
    def touch(options={})
      fu(:touch, options, list){ |opts| ::FileUtils.touch(list, **opts) }
    end

    # Stage files: hard link each into +dir+, at its path relative to
    # the batch's own directory. This is like #install but uses hardlinks.
    def stage(dir, options={})
      stage = localize(dir)
      entries.each do |entry|
        src  = localize(entry)
        dest = File.join(stage, entry.to_s)
        if File.directory?(src)
          fu(:mkdir_p, options, dest){ |opts| ::FileUtils.mkdir_p(dest, **opts) }
        else
          fu(:mkdir_p, options, File.dirname(dest)){ |opts| ::FileUtils.mkdir_p(File.dirname(dest), **opts) }
          fu(:ln, options, src, dest){ |opts| ::FileUtils.ln(src, dest, **opts) }
        end
      end
      dir
    end

    # Convenient alias for #map_mv.
    def rename(options={}, &block)
      map_mv(options, &block)
    end

    # Rename the list of files in batch, using a block to determine the new
    # names. If the block returns nil, the file will not be renamed.
    #
    # This is similar to #mv, but allows for detailed control over the renaming.
    #
    # Unlike the other `map_*` methods, this changes the Batch list in-place,
    # since the files renamed no loner exist.
    #
    # Returns the changed FileList instance.
    def map_mv(options={}, &block)
      @file_list = map_send(:mv, options, &block)
    end

    # Hard link the list of files in batch, using a block to determine the new
    # names. If the block returns nil, the file will not be linked.
    #
    # This is similar to #ln, but allows for detailed control over the link names.
    def map_ln(options={}, &block)
      map_send(:ln, options, &block)
    end

    # Soft link the list of files in batch, using a block to determine the new
    # names. If the block returns nil, the file will not be linked.
    #
    # This is similar to #ln_s, but allows for detailed control over the link names.
    def map_ln_s(options={}, &block)
      map_send(:ln_s, options, &block)
    end

    # Force soft linking of the list of files in batch, using a block to 
    # determine the new names. If the block returns nil, the file will not
    # be linked.
    #
    # This is similar to #ln_sf, but allows for detailed control over the
    # link names.
    def map_ln_sf(options={}, &block)
      map_send(:ln_sf, options, &block)
    end

    # Copy the list of files in batch, using a block to determine the new
    # file names. If the block returns nil, the file will not be copied.
    #
    # This is similar to #cp, but allows for detailed control over the new
    # file names.
    def map_cp(options={}, &block)
      map_send(:cp, options, &block)
    end

    # Copy the list of files recursively in batch, using a block to determine
    # the new file names. If the block returns nil, the file will not be copied.
    #
    # This is similar to #cp_r, but allows for detailed control over the new
    # file names.
    def map_cp_r(options={}, &block)
      map_send(:cp_r, options, &block)
    end

#    # Force copy the list of files recursively in batch, using a block to
#    # determine the new file names. If the block returns nil, the file will not
#    # be copied.
#    #
#    # This is similar to #cp_rf, but allows for detailed control over the new
#    # file names.
#    def map_cp_rf(options={}, &block)
#      map_send(:cp_rf, options, &block)
#    end

  private

    SAFE_METHODS = [:ln]

    # Generic name mapping procedure which can be used for any
    # FileUtils method that has a `src, dest` interface.
    #--
    # TODO: Make public?
    #++
    def map_send(method, options={}, &block)

      map = {}
      list.each do |file|
        if dest = block.call(file)
          map[file] = dest
        end
      end

      if options[:safe] or !options[:force] or SAFE_METHODS.include?(method) 
        ensure_safe(map)
      end

      map.each do |src, dest|
        fu(method, options, src, dest) do |opts|
          takes = ::FileUtils.method(method).parameters.map{ |_, name| name }
          opts.delete(:force) unless takes.include?(:force)
          ::FileUtils.rm_f(dest) if options[:force] && !takes.include?(:force) && File.file?(dest)
          ::FileUtils.__send__(method, src, dest, **opts)
        end
      end
      FileList.all(*map.values)
    end

    # Given a map of source to destination, this method ensures
    # a FileUtils operation can is "safe" --that the destination does not
    # yet and exist and/or the source and destination are compatible. 
    # If nota file rrror is raised.
    def ensure_safe(map)
      map.each do |src, dest|
        raise Errno::ENOENT, src.to_s unless File.exist?(src)
        if File.directory?(src)
          if File.directory?(dest)
            new_map = {}
            Dir.entries(src).each do |e|
              next if e == '.' or e == '..'
              new_map[File.join(src, e)] = File.join(dest, e)
            end
            ensure_safe(new_map)
          else
            raise Errno::EISDIR, "Is a directory - #{src}"
          end
        else
          if File.directory?(dest)
            check = File.join(dest, src)
            if File.exist?(check)
              raise Errno::EEXIST, "File exists - #{check}"
            end
          else
            raise Errno::EEXIST, "File exists - #{dest}" if File.exist?(dest)
          end
        end
      end
    end

  public

    # An intergrated glob like method that takes a set of include globs,
    # exclude globs and ignore globs to produce a collection of paths.
    #
    # Ignore_globs differ from exclude_globs in that they match by
    # the basename of the path rather than the whole pathname.
    #
    #def amass(include_globs, exclude_globs=[], ignore_globs=[])
    #  locally do
    #    fileutils.amass(include_globs, exclude_globs, ignore_globs)
    #  end
    #end

    # Is +path+ out-of-date in comparsion to all files in batch.
    def outofdate?(path)
      path = localize(path)
      return true unless File.exist?(path)
      return true if list.empty?
      File.mtime(path) < list.map{ |f| File.mtime(f) }.max
    end

    # Is +path+ up-to-date in comparsion to all files in batch.
    def uptodate?(path)
      ::FileUtils.uptodate?(localize(path), list)
    end

    #
    def noop?
      !!(@options[:noop] or @options[:nowrite] or @options[:dryrun])
    end

    #
    def verbose?
      !!(@options[:verbose] or @options[:trace] or @options[:dryrun])
    end
    alias_method :trace?, :verbose?

    #
    def dryrun?
      noop? && verbose?
    end

  private

    # A path taken from the batch's own directory, unless it is absolute.
    def localize(path)
      path = path.to_s
      return path if FileTest.absolute?(path) || local.to_s == '.'
      File.join(local.to_s, path)
    end

    # How each file operation reads in a trace.
    FU_COMMANDS = {
      :mkdir_p=>'mkdir -p', :rm_r=>'rm -r', :rm_f=>'rm -f', :rm_rf=>'rm -rf',
      :ln_s=>'ln -s', :ln_sf=>'ln -sf', :cp_r=>'cp -r',
      :chmod_R=>'chmod -R', :chown_R=>'chown -R'
    }

    # Carry out a file operation in the batch's mode: report it if
    # tracing, with the paths as they were given, and yield the options
    # for FileUtils unless this is a noop.
    def fu(name, options, *args)
      opts    = fu_options(options)
      noop    = opts.delete(:noop)
      verbose = opts.delete(:verbose)
      if verbose
        $stderr.puts [FU_COMMANDS[name] || name.to_s, *args.flatten].join(' ')
      end
      yield(opts) unless noop
    end

    # The options given for one command, with :noop and :verbose turned
    # on if the batch's mode says so.
    def fu_options(options)
      opts = {}
      (options || {}).each{ |k, v| opts[k.to_sym] = v }
      given   = [:dryrun, :nowrite, :noop, :trace, :verbose].select{ |k| opts.delete(k) }
      dryrun  = given.include?(:dryrun)
      opts[:noop]    = true if noop?    || dryrun || given.include?(:nowrite) || given.include?(:noop)
      opts[:verbose] = true if verbose? || dryrun || given.include?(:trace)   || given.include?(:verbose)
      opts.delete(:safe)
      opts
    end

  end

end

