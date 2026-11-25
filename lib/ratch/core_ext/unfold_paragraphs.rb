# TODO: Replace with facets/string/unfold

class String

  #
  def unfold_paragraphs
    text = String.new
    split(/\n/).each do |line|
      if /\S/ !~ line
        text << "\n\n"
      else
        if /^(\s+|[*])/ =~ line
          text << (line.rstrip + "\n")
        else
          text << (line.rstrip + " ")
        end
      end
    end
    text = text.gsub("\n\n\n","\n\n")
    return text
  end

end

