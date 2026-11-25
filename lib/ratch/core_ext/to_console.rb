# TODO: Improve the naming scheme of these methods.

#
class Array #:nodoc:

  # Convert an array into commandline parameters.
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]

  def to_console
    require 'shellwords'
    Shellwords.join(to_argv)
  end

  # TODO: DEPRECATE
  alias_method :to_params, :to_console

  #
  def to_argv
    args  = dup
    flags = (Hash===args.last ? args.pop : {})
    flags.to_argv + args.map{ |a| a.to_s }
  end

#   def to_console
#     flags = (Hash===last ? pop : {})
#     flags = flags.collect do |f,v|
#       m = f.to_s.size == 1 ? '-' : '--'
#       case v
#       when Array
#         v.collect{ |e| "#{m}#{f} '#{e}'" }.join(' ')
#       when true
#         "#{m}#{f}"
#       when false, nil
#         ''
#       else
#         "#{m}#{f} '#{v}'"
#       end
#     end
#     return (flags + self).join(" ")
#   end

end

class Hash

  # Convert a Hash into command line arguments.
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]
  def to_console
    require 'shellwords'
    Shellwords.join(to_argv)
  end

  # Convert a Hash into command line parameters, one string per
  # parameter, as a program receives them (so with no quoting).
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]
  def to_argv
    flags = []
    each do |f,v|
      m = f.to_s.size == 1 ? '-' : '--'
      case v
      when Array
        v.each{ |e| flags << (m == '-' ? "-#{f}#{e}" : "--#{f}=#{e}") }
      when true
        flags << "#{m}#{f}"
      when false, nil
        # nothing
      else
        flags << (m == '-' ? "-#{f}#{v}" : "--#{f}=#{v}")
      end
    end
    flags
  end

  # Turn a hash into arguments.
  #
  #   h = { :list => [1,2], :base => "HI" }
  #   h.argumentize #=> [ [], { :list => [1,2], :base => "HI" } ]
  #   h.argumentize(:list) #=> [ [1,2], { :base => "HI" } ]
  #
  def argumentize(args_field=nil)
    config = dup
    if args_field
      args = [config.delete(args_field)].flatten.compact
    else
      args = []
    end
    args << config
    return args
  end

  alias_method :command_vector, :argumentize

end

