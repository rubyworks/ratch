
  #
  # Generate RDoc documentation.
  #
  def rdoc(*files)
    require 'rdoc/rdoc'

    opts = {}
    opts.update(files.pop) while Hash===files.last

    opts[:output] ||= 'doc/rdoc'
    opts[:main]   ||= Dir.glob('README*').first

    output = opts[:output]

    # TODO: I think there is a File method that check this better, ie. File.safe? or something like that.
    raise "Output is not a relative path -- #{output}" if output =~ /^\//

    if uptodate?(output, *files) && !force?
      puts "#{output} is up-to-date."
      return
    end

    if File.exist?(output)
      #p Dir.pwd, opts[:output]
      rm_r output
    end

    args = opts.to_argv + files

    r = RDoc::RDoc.new
    r.document args

    #c = []
    #c << "rdoc"
    #c << "-m #{opts[:main]}"   if opts[:main]
    #c << "-o #{opts[:output]}" if opts[:output]
    #c.concat(files)
    #sh cmd
  end

  #
  # Generate RI documentation.
  #
  def ridoc(*files)
    require 'rdoc/rdoc'

    opts = {}
    opts.update(files.pop) while Hash===files.last

    opts[:output] ||= 'doc/ri'

    output = opts[:output]

    # TODO: I think there is a File method that check this better, ie. File.safe? or something like that.
    raise "Output is not a relative path -- #{output}" if output =~ /^\//

    if uptodate?(output, *files) && !force?
      puts "#{output} is up-to-date."
      return
    end

    if File.exist?(output)
      #p Dir.pwd, opts[:output]
      rm_r output
    end

    args = ["--ri"] + opts.to_argv + files

    r = RDoc::RDoc.new
    r.document args

    #c << "-m #{opts[:main]}" if opts[:main]
    #c << "-m #{opts[:output]}" if opts[:output]
    #sh cmd
  end
