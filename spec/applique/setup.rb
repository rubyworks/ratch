require 'fileutils'

Before :demo do
  File.open('foo.txt', 'w'){ |f| f << 'FOO TEXT' }
  FileUtils.mkdir_p('zoo')
  File.open('zoo/bar.txt', 'w'){ |f| f << 'ZOO BAR TEXT' }
end

