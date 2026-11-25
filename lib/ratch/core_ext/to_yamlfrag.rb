require 'yaml'

class Object

  # Same as #to_yaml but without the initial `---` line, or the `...`
  # line that ends a document holding a plain value.
  def to_yamlfrag
    str = to_yaml
    if /\A--- !/ =~ str
      str = str.sub(/\A--- !.*?$/, '')
    else
      str = str.sub(/\A---\s*/, '')
    end
    str.chomp("\n...\n").rstrip
  end

end
