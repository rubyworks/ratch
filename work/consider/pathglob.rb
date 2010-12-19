require 'ratch/ruby/pathname'

# = Pathglob
#
# A lazy resolution variation of Pathname.
#
# TODO: Is there any way to integrate this into Pathname itself
# as a mode of operation?
class Pathglob < Pathname

  def to_s
    Dir.glob(super).first
  end

end
