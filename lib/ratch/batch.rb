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

    #
    def self.[](*patterns)
      new('.', *patterns)
    end

    #
    def initialize(local, *patterns)
      @local   = Pathname.new(local)
      @options = (Hash === patterns.last ? patterns.pop : {}).rekey(&:to_sym)

      @file_list = FileList.all

      patterns.each do |pattern|
        if @local == Pathname.new('.')
          @file_list.add(pattern)
        else
          @file_list.add(File.join(local,pattern))
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
    def exists?     ; all?{ |path| FileTest.exists?(path)     } ; end
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
      list.map{ |dir| fileutils.mkdir(dir, options) }
    end

    # Make a directory for every entry.
    def mkdir_p(options={})
      list.each do |dir|
        if File.exist?(dir) && !File.directory?(dir)
          raise Errno::EEXIST, "File exists - #{dir}"
        end
      end
      list.map{ |dir| fileutils.mkdir_p(dir, options) }
    end
    alias_method :mkpath, :mkdir_p

    # Remove every directory.
    def rmdir(options={})
      list.map{ |dir| fileutils.rmdir(dir, options) }
    end

    # ln(list, destdir, options={})
    def ln(dir, options={})
      #src = list.to_a
      #new = localize(new)
      fileutils.ln(list, dir, options)
    end
    alias_method :link, :ln

    # ln_s(list, destdir, options={})
    def ln_s(dir, options={})
      #src = list.to_a
      #new = localize(new)
      fileutils.ln_s(list, dir, options)
    end
    alias_method :symlink, :ln_s

    def ln_sf(dir, options={})
      #src = list.to_a
      #new = localize(new)
      fileutils.ln_sf(list, dir, options)
    end

    # cp(list, dir, options={})
    def cp(dir, options={})
      #src  = list.to_a
      #dest = localize(dest)
      fileutils.cp(list, dir, options)
    end
    alias_method :copy, :cp

    # cp_r(list, dir, options={})
    def cp_r(dir, options={})
      #src  = list.to_a
      #dest = localize(dest)
      fileutils.cp_r(list, dir, options)
    end

    # mv(list, dir, options={})
    def mv(dir, options={})
      #src  = list.to_a
      #dest = localize(dest)
      fileutils.mv(list, dir, options)
    end
    alias_method :move, :mv

    #
    def rm(options={})
      list = list.to_a
      fileutils.rm(list, options)
    end

    # Alias for #rm.
    alias_method :remove, :rm

    # Remove, recursively removing the contents of directories.
    def rm_r(options={})
      #list = list.to_a
      fileutils.rm_r(list, options)
    end

    # Remove, with force option.
    def rm_f(options={})
      #list = list.to_a
      fileutils.rm_f(list, options)
    end

    # Remove with force option, recursively removing the contents of directories.
    def rm_rf(options={})
      #list = list.to_a
      fileutils.rm_rf(list, options)
    end

    # Install files to a directory with given mode. Unlike #cp, this will
    # not copy the file if an up-to-date copy already exists.
    def install(dir, mode, options={})
      #src = list.to_a
      #dest = localize(dest)
      fileutils.install(list, dir, mode, options)
    end

    # Change mode of files.
    def chmod(mode, options={})
      #list = list.to_a
      fileutils.chmod(mode, list, options)
    end

    # Change mode of files, following directories recursively.
    def chmod_r(mode, options={})
      #list = list.to_a
      fileutils.chmod_r(mode, list, options)
    end
    #alias_method :chmod_R, :chmod_r

    # Change owner of files.
    def chown(user, group, options={})
      #list = list.to_a
      fileutils.chown(user, group, list, options)
    end

    # Change owner of files, following directories recursively.
    def chown_r(user, group, options={})
      #list = list.to_a
      fileutils.chown_r(user, group, list, options)
    end
    #alias_method :chown_R, :chown_r

    # Touch each file.
    def touch(options={})
      #list = list.to_a
      fileutils.touch(list, options)
    end

    # Stage files. This is like #install but uses hardlinks.
    def stage(dir)
      #dir   = localize(directory)
      #files = localize(files)
      #list = list.to_a
      fileutils.stage(dir, local, list)
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
      @file_list = map_send(:mv, options={}, &block)
    end

    # Hard link the list of files in batch, using a block to determine the new
    # names. If the block returns nil, the file will not be linked.
    #
    # This is similar to #ln, but allows for detailed control over the link names.
    def map_ln(options={}, &block)
      map_send(:ln, options={}, &block)
    end

    # Soft link the list of files in batch, using a block to determine the new
    # names. If the block returns nil, the file will not be linked.
    #
    # This is similar to #ln_s, but allows for detailed control over the link names.
    def map_ln_s(options={}, &block)
      map_send(:ln_s, options={}, &block)
    end

    # Force soft linking of the list of files in batch, using a block to 
    # determine the new names. If the block returns nil, the file will not
    # be linked.
    #
    # This is similar to #ln_sf, but allows for detailed control over the
    # link names.
    def map_ln_sf(options={}, &block)
      map_send(:ln_sf, options={}, &block)
    end

    # Copy the list of files in batch, using a block to determine the new
    # file names. If the block returns nil, the file will not be copied.
    #
    # This is similar to #cp, but allows for detailed control over the new
    # file names.
    def map_cp(options={}, &block)
      map_send(:cp, options={}, &block)
    end

    # Copy the list of files recursively in batch, using a block to determine
    # the new file names. If the block returns nil, the file will not be copied.
    #
    # This is similar to #cp_r, but allows for detailed control over the new
    # file names.
    def map_cp_r(options={}, &block)
      map_send(:cp_r, options={}, &block)
    end

#    # Force copy the list of files recursively in batch, using a block to
#    # determine the new file names. If the block returns nil, the file will not
#    # be copied.
#    #
#    # This is similar to #cp_rf, but allows for detailed control over the new
#    # file names.
#    def map_cp_rf(options={}, &block)
#      map_send(:cp_rf, options={}, &block)
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
        fileutils.__send__(method, src, dest, options)
      end
      FileList.all(*map.values)
    end

    # Given a map of source to destination, this method ensures
    # a FileUtils operation can is "safe" --that the destination does not
    # yet and exist and/or the source and destination are compatible. 
    # If nota file rrror is raised.
    def ensure_safe(map)
      map.each do |src, dest|
        raise unless File.exist?(src)
        if File.directory?(src)
          if File.directory?(dest)
            new_map = {}
            Dir.entries(src).each |e|
              next if e == '.' or e == '..'
              new_map[File.join(src, e)] = File.join(dest, e)
            end
            ensure_safe_destination(new_map)
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
      fileutils.outofdate?(path, to_a)
    end

    # Is +path+ up-to-date in comparsion to all files in batch.
    def uptodate?(path)
      fileutils.uptodate?(path, to_a)
    end

    #
    def noop?
      @options[:noop] or @options[:dryrun]
    end

    #
    def verbose?
      @options[:verbose] or @options[:dryrun]
    end

    #
    def dryrun?
      noop? && verbose?
    end

  private

    # Returns FileUtils module based on mode.
    def fileutils
      if dryrun?
        ::FileUtils::DryRun
      elsif noop?
        ::FileUtils::Noop
      elsif verbose?
        ::FileUtils::Verbose
      else
        ::FileUtils
      end
    end

  end

end

