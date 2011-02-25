--- 
name: ratch
spec_version: 1.0.0
repositories: 
  public: git://github.com/rubyworks/ratch.git
title: Ratch
contact: trans <transfire@gmail.com>
requires: 
- group: []

  name: facets
  version: 2.9.1+
- group: []

  name: minitar
  version: 0.5.3+
- group: 
  - test
  name: ko
  version: 1.2.0~
- group: 
  - test
  name: qed
  version: 0+
- group: 
  - build
  name: syckle
  version: 0+
resources: 
  code: http://github.org/rubyworks/ratch
  mail: http://groups.gooogle.com/group/rubyworks-mailinglist
  home: http://rubyworks.github.org/ratch
manifest: 
- .ruby
- bin/ludo
- bin/ratch
- lib/ratch/batch.rb
- lib/ratch/console.rb
- lib/ratch/core_ext/facets.rb
- lib/ratch/core_ext/filetest.rb
- lib/ratch/core_ext/to_actual_filename.rb
- lib/ratch/core_ext/to_console.rb
- lib/ratch/core_ext/to_list.rb
- lib/ratch/core_ext/to_yamlfrag.rb
- lib/ratch/core_ext/unfold_paragraphs.rb
- lib/ratch/core_ext.rb
- lib/ratch/file_list.rb
- lib/ratch/script/help.rb
- lib/ratch/script.rb
- lib/ratch/shell.rb
- lib/ratch/system.rb
- lib/ratch/utils/cli.rb
- lib/ratch/utils/config.rb
- lib/ratch/utils/email.rb
- lib/ratch/utils/ftp.rb
- lib/ratch/utils/pom.rb
- lib/ratch/utils/rdoc.rb
- lib/ratch/utils/tar.rb
- lib/ratch/utils/xdg.rb
- lib/ratch/utils/zlib.rb
- lib/ratch.rb
- lib/ratch.yml
- man/ratch.1
- spec/applique/array.rb
- spec/applique/setup.rb
- spec/batch.rdoc
- spec/script.rdoc
- spec/shell.rdoc
- spec/system.rdoc
- test/case_batch.rb
- test/case_shell.rb
- test/core_ext/case_pathname.rb
- test/helper.rb
- test/utils/case_cli.rb
- test/utils/case_config.rb
- test/utils/case_email.rb
- test/utils/case_ftp.rb
- test/utils/case_pom.rb
- test/utils/case_rdoc.rb
- test/utils/case_tar.rb
- test/utils/case_zlib.rb
- test/utils/fixtures/pom_sample/Profile
- test/utils/fixtures/rdoc_sample/README.rdoc
- test/utils/fixtures/rdoc_sample/lib/rdoc_sample/rdoc_sample.rb
- README.rdoc
- History.rdoc
- Version
- License.txt
- COPYING
version: 1.2.0
licenses: 
- Apache 2.0
copyright: Copyright (c) 2009 Thomas Sawyer
description: Ratch is a Ruby-based batch scripting language. It's a DSL over regular Ruby to make the life of the batch script writter easier.
summary: Ruby-based Batch Scripting
organization: RubyWorks
authors: 
- Trans <transfire@gmail.com>
created: 2009-09-22
