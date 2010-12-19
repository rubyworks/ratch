#
# Generate Packages using Box packaging tool.
#
def box(options)
  require 'box'

  opts  = options.rekey

  types = opts.delete(:types)

  # TODO: Add MANIFEST generation here if requested.

  options[:types].each do |type|
    case type
    when 'zip'
      Box::Zip.new(loc, opts).package
    when 'tar'
      Box::Tar.new(loc, opts).package
    when 'gem'
      Box::Gem.new(loc, opts).package
    end
  end
end
