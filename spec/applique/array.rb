class ::Array

  # Helper extension for comparison tests.
  def to_pathnames
    map{ |f| Pathname.new(f) }
  end

end
