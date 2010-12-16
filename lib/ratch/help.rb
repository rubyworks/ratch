module Ratch

  # Support class for displaying command help lists.
  class Help

    #
    def self.list(*dirs)
      tasks = script_descriptions(*dirs)
      tmax  = tasks.keys.max{ |a,b| a.size <=> b.size }.size
      #dmax  = dirs.flatten.max{ |a,b| a.size <=> b.size }.size
      #if dir == ''
      #  max += 4 + 2
      #else
        max = tmax + 4
      #end
      tasks = tasks.sort_by{|k,v| k }
      tasks.each do |name, sum|
        #if dir == ''
        #  cmd = "ratch #{name}"
        #else
          cmd = name
        #end
        puts "%-#{max}s # %s" % [cmd, sum]
      end
    end

    # Scan task scripts for descriptions.
    def self.script_descriptions(*dirs)
      opts  = Hash === dirs.last ? dirs.pop : {}
      dirs  = dirs.flatten
      help  = {}
      dirs.each do |dir|
        files = Dir.glob(File.join(dir,'**/*'))
        files.each do |fname|
          next if FileTest.directory?(fname)
          next if opts[:exe] and !FileTest.executable?(fname)
          desc = ''
          File.open(fname) do |f|
            line = ''
            until f.eof?
              line = f.gets
              case line
              when /^(#!|\s*$)/
                next
              when /^\s*#(.*)/
                desc = $1.strip; break
              else
                desc = nil; break
              end
            end
          end
          key = opts[:exe] ? fname : fname.sub(dir+'/', '')
          help[key] = desc
        end
      end
      help
    end

    # Scan script for description header.
    def self.header(file, opts={})
      #next if FileTest.directory?(file)
      #next if opts[:exe] and !FileTest.executable?(file)
      desc = "\n"
      File.open(file) do |f|
        line = ''
        until f.eof?
          line = f.gets
          case line
          when /^(#!|\s*$)/
            next
          when /^\s*#\s?(.*)/
            desc << $1.rstrip + "\n"
          else
            break
          end
        end
      end
      desc + "\n"
    end

  end

end

