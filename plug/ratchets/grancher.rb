module Ratchets

  #
  def grancher(options={}, &block)
    require 'grancher'

    options = options.merge(block.to_h) if block

    copy = options[:copy]

    #copy = copy.reject{ |*c| !File.exist?(c.first) }

    dirs, files = copy.partition{ |*c| File.directory?(c.first) }

    grancher = Grancher.new do |g|
      g.branch  = options[:branch]   || 'gh-pages'
      g.push_to = options[:push_to]  || 'origin'
      g.repo    = options[:repo]    # defaults to '.'
      g.message = options[:message] # defaults to 'Updated files.'

      dirs.each do |*c|
        g.directory *c
      end

      files.each do |*c|
        g.file *c
      end
    end
    grancher.commit
    grancher.push
  end

end

