module Ratch

  # FIXME: This module needs major work. Methods #ftp_files and
  # ftp_stage_transfer need to either be generalized and moved to
  # Shell or Script, or removed.
  #
  module FTPUtils

    def self.included(base)
      require 'net/ftp'
      require 'net/sftp'
    end

    def self.extended(base)
      included(base)
    end

    # Use ftp to upload files.
    #
    def ftp(keys)
      keys = upload_parameters(keys)

      # set transfer rules
      if keys.stage
        trans = ftp_stage_transfer(keys.stage)
      else
        ftp_files(keys.dir, keys.copy).each do |from|
          trans << [from,from]
        end
      end

      # append location of publication dir to from
      dir = keys.dir
      trans.collect!{ |from,to| [File.join(dir,from), to] }

      if keys.dryrun
        puts "ftp open #{keys.user}@#{keys.host}:#{keys.root}/"
        keys.trans.each do |f, t|
          puts "ftp put #{f} #{t}"
        end
      else
        Net::FTP.open(keys.host) do |ftp|
          ftp.login(keys.user) #password?
          ftp.chdir(keys.root)
          keys.trans.each do |f, t|
            puts "ftp #{f} #{t}" unless keys.quiet
            ftp.putbinaryfile( f, t, 1024 )
          end
        end
      end
    end

    # Use sftp to upload files.
    #
    def sftp( keys )
      keys = upload_parameters(keys)

      # set transfer rules
      if keys.stage
        trans = ftp_stage_transfer(keys.stage)
      else
        ftp_files(keys.dir, keys.copy).each do |from|
          trans << [from,from]
        end
      end

      # append location of publication dir to from
      dir = keys.dir
      trans.collect!{ |from,to| [File.join(dir,from), to] }

      if keys.dryrun
        puts "sftp open #{keys.user}@#{keys.host}:#{keys.root}/"
        keys.trans.each do |f,t|
          puts "sftp put #{f} #{t}"
        end
      else
        Net::SFTP.start(keys.host, keys.user, keys.pass) do |sftp|
          #sftp.login( user )
          sftp.chdir(keys.root)
          keys.trans.each do |f,t|
            puts "sftp #{f} #{t}" unless keys.quiet
            sftp.put_file(f,t) #, 1024 )
          end
        end
      end
    end

    # Put together the list of files to copy.
    def ftp_files( dir, copy )
      Dir.chdir(dir) do
        del, add = copy.partition{ |f| /^[-]/ =~ f }

        # remove - and + prefixes
        del.collect!{ |f| f.sub(/^[-]/,'') }
        add.collect!{ |f| f.sub(/^[+]/,'') }

        #del.concat(must_exclude)

        ftp_files = []
        add.each{ |g| files += Dir.glob(g) }
        del.each{ |g| files -= Dir.glob(g) }

        files.collect!{ |f| f.sub(/^\//,'') }

        return files
      end
    end

    # Combine three part stage list into a two part from->to list.
    #
    # Using the stage list of three space separated fields.
    #
    #   fromdir file todir
    #
    # This is used to generate a from -> to list of the form:
    #
    #  fromdir/file todir/file
    #
    def ftp_stage_transfer( list )
      trans = []
      list.each do |line|
        trans << Shellwords.shellwords(line)
      end

      trans.collect! do |from, base, to|
        file = File.join(from,base)
        to = File.join(to,base)
        [from, to]
      end
    end

  end

end
