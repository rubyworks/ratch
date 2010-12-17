--- 
name: ratch
loadpath: 
- lib
- vendor
repositories: 
  public: git://github.com/rubyworks/ratch.git
title: Ratch
contact: trans <transfire@gmail.com>
requires: 
- group: 
  - build
  name: syckle
  version: 0+
- group: 
  - test
  name: qed
  version: 0+
resources: 
  code: http://github.org/rubyworks/ratch
  mail: http://groups.gooogle.com/group/rubyworks-mailinglist
  home: http://rubyworks.github.org/ratch
pom_verison: 1.0.0
manifest: 
- .ruby
- bin/lt
- bin/ludo
- bin/ratch
- bin/rbat
- demo/tryme-task.ratch
- demo/tryme1.ratch
- lib/plugins/ratch/shell/email.rb
- lib/plugins/ratch/shell/rcov.rb
- lib/plugins/ratch/shell/rdoc.rb
- lib/plugins/rbat/demo
- lib/plugins/rbat/help
- lib/ratch/cli.rb
- lib/ratch/console.rb
- lib/ratch/core_ext/all.rb
- lib/ratch/core_ext/facets.rb
- lib/ratch/core_ext/filetest.rb
- lib/ratch/core_ext/fileutils.rb
- lib/ratch/core_ext/multiglob.rb
- lib/ratch/core_ext/object/to_yamlfrag.rb
- lib/ratch/core_ext/string/to_actual_filename.rb
- lib/ratch/core_ext/string/unfold_paragraphs.rb
- lib/ratch/core_ext/to_console.rb
- lib/ratch/core_ext/to_list.rb
- lib/ratch/help.rb
- lib/ratch/pathglob.rb
- lib/ratch/pathlist.rb
- lib/ratch/plugin.rb
- lib/ratch/ruby/filetest.rb
- lib/ratch/ruby/fileutils.rb
- lib/ratch/ruby/pathname.rb
- lib/ratch/script.rb
- lib/ratch/shell/ftp.rb
- lib/ratch/shell/gzip.rb
- lib/ratch/shell/tar.rb
- lib/ratch/shell/xdg.rb
- lib/ratch/shell/zip.rb
- lib/ratch/shell.rb
- lib/ratch/utils/log.rb
- lib/ratch/utils/platform.rb
- lib/ratch/utils/pom.rb
- lib/ratch.rb
- test/test_pathlist.rb
- test/test_pathname.rb
- test/test_pathshell.rb
- test/unit/test_helper.rb
- test/unit/test_task.rb
- README.rdoc
- NOTES.rdoc
- History.rdoc
- Version
- License.txt
- NEWS
- COPYING
version: 1.2.0
copyright: Copyright (c) 2009 Thomas Sawyer
licenses: 
- Apache 2.0
description: |-
  Ratch is a Ruby-based batch scripting language. It's a DSL over regular RUby to make the life of the batch script writter easier.
  Integrated set of a path-related libraries
  Path is all about paths. It's provides a reimplementation of the Ruby standard Pathname library, Path::Name, a superior globbing facility, Path::List and an isolated shell-evironment, Path::Shell.
organization: RubyWorks
summary: Ruby-based Batch Scripting
authors: 
- Trans <transfire@gmail.com>
created: 2009-09-22
