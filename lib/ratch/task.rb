
  module Taskable

    def self.included(base)
      base.extend(Dsl)
    end

    # Run a task. Better name?
    def run(target)
      #t = self.class.tasks(target)
      #t.run(self)
      send("#{target}:target")
    end

    module Dsl
      # Without an argument, returns list of tasks defined for this class.
      #
      # If a task's target name is given, will return the first
      # task mathing the name found in the class' inheritance chain.
      # This is important ot ensure task are inherited in the same manner
      # that methods are.
      def tasks(target=nil)
        if target
          target = target.to_sym
          anc = ancestors.select{|a| a < Taskable}
          t = nil; anc.find{|a| t = a.tasks[target]}
          return t
        else
          @tasks ||= {}
        end
      end

      # Set a description to be used by then next defined task in this class.
      def desc(description)
        @desc = description
      end

      # Define a task.
      def task(target_and_requisite, &function)
        target, requisite, function = *Task.parse_arguments(target_and_requisite, &function)
        task = tasks[target.to_sym] ||= (
          tdesc = @desc
          @desc = nil
          Task.new(self, target, tdesc) #, reqs, actions)
        )
        task.update(requisite, &function)
        define_method("#{target}:target"){ task.run(self) }  # or use #run?
        define_method("#{target}:task", &function) # TODO: in 1.9 use instance_exec instead.
      end
    end

    # = Task Class
    #
    class Task
      attr :base
      attr :target
      attr :requisite
      attr :function
      attr :description

      def initialize(base, target, description=nil, requisite=nil, &function)
        @base        = base
        @target      = target.to_sym
        @description = description
        @requisite   = requisite || []
        @function    = function
      end

      #
      def update(requisite, &function)
        @requisite.concat(requisite).uniq!
        @function = function if function
      end

      #
      def prerequisite
        base.ancestors.select{|a| a < Taskable}.collect{ |a|
          a.tasks[target].requisite
        }.flatten.uniq
      end

      # invoke target
      def run(object)
        rd = rule_dag
        rd.each do |t|
          object.send("#{t}:task")
        end
      end

      #
      #def call(object)
      #  object.instance_eval(&function)
      #end

      # Collect task dependencies for running.
      def rule_dag(cache=[])
        prerequisite.each do |r|
          next if cache.include?(r)
          t = base.tasks[r]
          t.rule_dag(cache)
          #cache << dep
        end
        cache << target.to_s
        cache
      end

      #
      def self.parse_arguments(name_and_reqs, &action)
        if Hash===name_and_reqs
          target = name_and_reqs.keys.first.to_s
          reqs = [name_and_reqs.values.first].flatten
        else
          target = name_and_reqs.to_s
          reqs = []
        end
        return target, reqs, action
      end
    end

    # = File Task Class
    #
    class FileTask < Task

      def needed?
        if prerequisite.empty?
          dated = true
        elsif File.exist?(target)
          mtime = File.mtime(target)
          dated = prerequisite.find do |file|
            !File.exist?(file) || File.mtime(file) > mtime
          end
        else
          dated = true
        end
        return dated
      end

      #
      def call(object)
        object.instance_eval(&function) if needed?
      end
    end

  end


=begin
    # turn yaml file into tasks
    def parse(file)
      script = YAML.load(File.new(file.to_s))

      imports = script.delete('import')   || []
      #plugins = script.delete('plugin')   || []
      srvs    = script.delete('services') || {}
      tgts    = script.delete('targets')  || {}

      imports.each do |import|
        path = Reap::Domain::LIB_DIRECTORY + 'systems' + (import + '.reap').to_s
        parse(path)
      end

      srvs.each do |label, options|
        type = options.delete('type')
        @services[label] = domain.send("#{type}_service")  # FIXME
      end

      tgts.each do |target, options|
        @targets[target] = Task.new(self, target, options)
      end
    end
=end






=begin
    # Collect task dependencies for running.
    def self.rule_dag(target, cache=[])
      t = tasks[target.to_sym]
      d = t.prerequisite
      d.each do |r|
        next if cache.include?(r)
        rule_dag(r, cache)
        #cache << dep
      end

      # file requirements
      #q = self.class.ann(name, :reqs) || []
      #q.each do |req|
      #  path = Pathname.new(req)
      #  next if r.include?(path)
      #  mat = annotations.select{ |n, a| File.fnmatch?(a[:file].first, req) if a[:file] }.compact
      #  mat.each do |n, a|
      #    rule_dag(n, r)
      #  end
      #  r << path
      #end

      cache << target.to_s
      return cache
    end

    # invoke target
    def run(target)
      target = target.to_sym
      rd = self.class.rule_dag(target)
      rd.each do |t|
        send("#{t}:task")
      end
    end
=end

=begin
        if target == name.to_s
          tasks[target].call
        else
          case action
          when Pathname
            raise unless action.exist?
          else
            run_rec(action)
          end
        end
      end
    end

    def run_rec(action)
      # creates a file?
      dated = true
      if creates = self.class.ann(action, :file)
        if self.class.ann(name, :reqs).empty?
          dated = true
        elsif File.exist?(creates)
          mtime = File.mtime(creates)
          dated = self.class.ann(name, :reqs).find do |file|
            !File.exist?(file) || File.mtime(file) > mtime
          end
        else
          dated = true
        end
      end
      return unless dated
      send(action)
    end
=end


