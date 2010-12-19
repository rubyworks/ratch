module Ratch

  # Proccess a list of files in batch.
  # The Batch interface mimics the Shell class in most respects.
  class Batch
    include Enumerable

    #
    attr :local

    #
    def initialize(local, *globs)
      @local = Pathname.new(local)
      @list  = FileList.new(*globs)
    end

    #
    def each(&blk)
      @list.each(&blk)
    end

    #
    def [](*entries)
      entries.each do |entry|
        case entry
        when Pathname
          push(@local + entry)
        else
          concat(Dir.glob(@local + entry).map{ |f| Pathname.new(f) })
        end
      end
      return self
    end

    # relative to local
    def entries
      map{ |entry| entry.sub(local+'/','') }
    end

    #def each
    #  super{
    #    yield(@local + entry)
    #  }
    #end

    #############
    # FileTest  #
    #############

    #
    def size
      inject(0){ |sum, path| sum + FileTest.size(path) }
    end
    alias_method :size?, :size

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

    # Will these work since all paths are localized?
    def relative?   ; all?{ |path| FileTest.relative?(path)   } ; end
    def absolute?   ; all?{ |path| FileTest.absolute?(path)   } ; end

    def writable_real?   ; all?{ |path| FileTest.writable_real?(path)   } ; end
    def executable_real? ; all?{ |path| FileTest.executable_real?(path) } ; end
    def readable_real?   ; all?{ |path| FileTest.readable_real?(path)   } ; end

    alias_method :dir?, :directory?

    def identical?(other)
      all?{ |path| FileTest.identical?(path, other)  }
    end
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

    # Present working directory. (?)
    def pwd
      @local
    end

    #
    def mkdir(options={})
      map{ |dir| fileutils.mkdir(dir, options) }
    end

    def mkdir_p(options={})
      map{ |dir| fileutils.mkdir_p(dir, options) }
    end
    alias_method :mkpath, :mkdir_p

    def rmdir(options={})
      map{ |dir| fileutils.rmdir(dir, options) }
    end

    # ln(list, destdir, options={})
    def ln(new, options={})
      src = to_a
      #new = localize(new)
      fileutils.ln(src, new, options)
    end
    alias_method :link, :ln

    # ln_s(list, destdir, options={})
    def ln_s(new, options={})
      src = to_a
      #new = localize(new)
      fileutils.ln_s(src, new, options)
    end
    alias_method :symlink, :ln_s

    def ln_sf(new, options={})
      src = to_a
      #new = localize(new)
      fileutils.ln_sf(src, new, options)
    end

    # cp(list, dir, options={})
    def cp(dest, options={})
      src  = to_a
      #dest = localize(dest)
      fileutils.cp(src, dest, options)
    end
    alias_method :copy, :cp

    # cp_r(list, dir, options={})
    def cp_r(dest, options={})
      src  = to_a
      #dest = localize(dest)
      fileutils.cp_r(src, dest, options)
    end

    # mv(list, dir, options={})
    def mv(dest, options={})
      src  = to_a
      #dest = localize(dest)
      fileutils.mv(src, dest, options)
    end
    alias_method :move, :mv

    def rm(options={})
      list = to_a
      fileutils.rm(list, options)
    end
    alias_method :remove, :rm

    def rm_r(options={})
      list = to_a
      fileutils.rm_r(list, options)
    end

    def rm_f(list, options={})
      list = to_a
      fileutils.rm_f(list, options)
    end

    def rm_rf(list, options={})
      list = to_a
      fileutils.rm_rf(list, options)
    end

    def install(src, dest, mode, options={})
      src  = to_a
      #dest = localize(dest)
      fileutils.install(src, dest, mode, options)
    end

    def chmod(mode, list, options={})
      list = to_a
      fileutils.chmod(mode, list, options)
    end

    def chmod_r(mode, list, options={})
      list = to_a
      fileutils.chmod_r(mode, list, options)
    end
    #alias_method :chmod_R, :chmod_r

    def chown(user, group, list, options={})
      list = to_a
      fileutils.chown(user, group, list, options)
    end

    def chown_r(user, group, list, options={})
      list = to_a
      fileutils.chown_r(user, group, list, options)
    end
    #alias_method :chown_R, :chown_r

    def touch(list, options={})
      list = to_a
      fileutils.touch(list, options)
    end

    #
    def stage(dir)
      #dir   = localize(directory)
      #files = localize(files)
      #fileutils.stage(dir, work, entries)
      fileutils.stage(dir, local, entries)
    end

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

    #
    def outofdate?(path)
      fileutils.outofdate?(path, to_a)
    end

    #
    def uptodate?(path)
      fileutils.uptodate?(path, to_a)
    end

    #
    #def uptodate?(new, old_list, options=nil)
    #  new = localize(new)
    #  old = localize(old_list)
    #  fileutils.uptodate?(new, old, options)
    #end

    #
    #def method_missing(s, *a, &b)
    #  entries.map do |e|
    #    e.__send__(s, *a, &b)
    #  end
    #end

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

