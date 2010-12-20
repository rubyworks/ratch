require 'fileutils'

#Before :demo do
#  clear_working_directory!
#end

When "consisting of the following entires" do |text|
  text.split(/\s+/).each do |file|
    if /\/$/ =~ file
      FileUtils.mkdir_p(file) unless File.directory?(file)
    else
      File.open(file, 'w+'){ |f| f << "SAMPLE #{file}".upcase }
    end
  end
end

When "Let's say we have a Ratch script called '(((.*?)))'" do |file, text|
  File.open(file, 'w'){ |f| f << text }
end

