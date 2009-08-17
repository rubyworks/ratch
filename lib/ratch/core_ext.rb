require 'facets'

#__DIR__ = File.dirname(__FILE__)

#Dir[File.join(__DIR__, 'core_ext', '*.rb')].each do |file|
#  require file
#end

class Object

  def to_yamlfrag
    to_yaml.sub("---",'').rstrip
  end

end

#
# Pathname extensions
# ----------------------------------------------------------------------------

require 'facets/pathname'

class Pathname

  # Like directory? but return self if true, otherwise nil.
  def dir?
    directory? ? self : nil
  end

# Already in Facets
#
#    def glob(*opts)
#      flags = 0
#      opts.each do |opt|
#        case opt when Symbol, String
#          flags += File.const_get("FNM_#{opt}".upcase)
#        else
#          flags += opt
#        end
#      end
#      self.class.glob(self.to_s, flags).collect{ |path| self.class.new(path) }
#    end
#
#    #
#    def first(*opts)
#      flags = 0
#      opts.each do |opt|
#        case opt when Symbol, String
#          flags += File.const_get("FNM_#{opt}".upcase)
#        else
#          flags += opt
#        end
#      end
#      file = self.class.glob(self.to_s, flags).first
#      file ? self.class.new(file) : nil
#    end

end

#
# String extensions
# ----------------------------------------------------------------------------

class String

  attr_accessor :color

  # Find actual filename (casefolding) and returns it.
  # Returns nil if no file is found.

  def to_actual_filename
    Dir.glob(self, File::FNM_CASEFOLD).first
  end

  # Find actual filename (casefolding) and replace string with it.
  # If file not found, string remains the same and method returns nil.

  def to_actual_filename!
    filename = to_actual_filename
    replace(filename) if filename
  end

  #
  def unfold_paragraphs
    blank = false
    text  = ''
    split(/\n/).each do |line|
      if /\S/ !~ line
        text << "\n\n"
        blank = true
      else
        if /^(\s+|[*])/ =~ line
          text << (line.rstrip + "\n")
        else
          text << (line.rstrip + " ")
        end
        blank = false
      end
    end
    text = text.gsub("\n\n\n","\n\n")
    return text
  end

end

#
# to_list methods
# ----------------------------------------------------------------------------

class Array #:nodoc:

  def to_list
    self
  end

end

class NilClass

  def to_list
    []
  end

end

class String

  # Helper method for cleaning list options.
  # This will split the option on ':' or ';'
  # if it is a string, rather than an array.
  # And it will make sure there are no nil elements.

  def to_list
    split(/[:;,\n]/)
  end

end

#
# to_console methods
# ----------------------------------------------------------------------------

#
class Array #:nodoc:

  # Convert an array into commandline parameters.
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]

  def to_console
    #flags = (Hash===last ? pop : {})
    #flags = flags.to_console
    #flags + ' ' + join(" ")
    to_argv.join(' ')
  end

  # TODO: DEPRECATE
  alias_method :to_params, :to_console

  #
  def to_argv
    flags = (Hash===last ? pop : {})
    flags = flags.to_argv
    flags + self
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
    to_argv.join(' ')
  end

  # Convert a Hash into command line parameters.
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]
  def to_argv
    flags = map do |f,v|
      m = f.to_s.size == 1 ? '-' : '--'
      case v
      when Array
        v.collect{ |e| "#{m}#{f}='#{e}'" }.join(' ')
      when true
        "#{m}#{f}"
      when false, nil
        ''
      else
        "#{m}#{f}='#{v}'"
      end
    end
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

