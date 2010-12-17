require 'fileutils'

module Path

  # DEPRECATE: will move to Confectionery project.

  # TODO: I would like to remove the depth parameter,
  # which would be easy enough if we had a null/nack
  # object, ie. a type of nil that returns itself on
  # missing methods.
  #
  class Store

    def self.load(dir)
      o = new(dir)
      o.prime!
      o
    end

    #
    def initialize(dir, data={}, depth=0)
      require 'yaml'

      @dir   = dir
      @data  = data
      @depth = depth

      #@save  = []
    end

    #
    def [](name)
      name = name.to_s
      if @data.key?(name)
        @data[name]
      else
        @data[name] = read!(name)
      end
    end

    # TODO: what if name is a directory?
    def []=(name, value)
      name = name.to_s
      #@save << name
      @data[name] = value
    end

    #
    def to_h
      Dir.entries(@dir).each do |fname|
        self[fname]
      end
      @data.dup
    end

    #
    def each(&block)
      @data.each(&block)
    end

    #
    #def to_yaml(opts={})
    #  @data.to_yaml(opts={})
    #end

    def to_yaml( opts = {} )
      YAML::quick_emit(self, opts) do |out|
        out.map(@data.taguri, to_yaml_style) do |map|
          each do |k, v|
            map.add(k, v)
          end
        end
      end
    end


    # TODO: raise if arguments are wrong.
    def method_missing(name, *a, &b)
      name = name.to_s
      case name
      when /\=$/
        self[name.chomp('=')] = a.first
      when /\?$/
        self[name.chomp('?')]
      when /\!$/
        super
      else
        self[name]
      end
    end

    def read!(name)
      file = File.join(@dir, name)
      if File.file?(file)
        YAML.load(File.new(file))
      elsif File.directory?(file)
        if @depth.zero?
          self.class.new(file)
        else
          self.class.new(file, depth - 1)
        end
      else
        if @depth.zero?
          nil
        else
          self.class.new(file)
        end
      end
    end

    #
    def save!
      @data.each do |name, value|
        file  = File.join(@dir,name)
        case value
        when self.class
          FileUtils.mkdir_p(@dir)
          value.save!
        else
          old = File.read(file) if File.exist?(file)
          new = value.to_yaml
          if old != new
            FileUtils.mkdir_p(@dir)
            File.open(file, 'w'){ |f| f << new }
          end
        end
      end
    end

    #
    def prime!(hash=nil)
      if hash
        hash.each do |k,v|
          case v
          when Hash
            self[k] = self.class.new(File.join(@dir,k),v)
          when self.class
            self[k] = self.class.new(File.join(@dir,k),v.to_h)
          else
            self[k] = v
          end
        end
      else
        entries = Dir.entries(@dir) - [ '.', '..' ]
        entries.each do |fname|
          v = self[fname]
          v.prime! if self.class === v
        end
      end
    end

    # Specify a node in the store as a branch with a fixed depth.
    def branch!(name, depth=1)
      path = File.join(@dir, name)
      self[name] = self.class.new(path, {}, depth)
    end

  end

end

