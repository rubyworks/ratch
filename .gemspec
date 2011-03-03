--- !ruby/object:Gem::Specification 
name: ratch
version: !ruby/object:Gem::Version 
  hash: 31
  prerelease: false
  segments: 
  - 1
  - 2
  - 0
  version: 1.2.0
platform: ruby
authors: 
- Trans <transfire@gmail.com>
autorequire: 
bindir: bin
cert_chain: []

date: 2011-03-03 00:00:00 -05:00
default_executable: 
dependencies: 
- !ruby/object:Gem::Dependency 
  name: facets
  prerelease: false
  requirement: &id001 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 41
        segments: 
        - 2
        - 9
        - 1
        version: 2.9.1
  type: :runtime
  version_requirements: *id001
- !ruby/object:Gem::Dependency 
  name: minitar
  prerelease: false
  requirement: &id002 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 13
        segments: 
        - 0
        - 5
        - 3
        version: 0.5.3
  type: :runtime
  version_requirements: *id002
- !ruby/object:Gem::Dependency 
  name: ko
  prerelease: false
  requirement: &id003 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        hash: 31
        segments: 
        - 1
        - 2
        - 0
        version: 1.2.0
  type: :development
  version_requirements: *id003
- !ruby/object:Gem::Dependency 
  name: qed
  prerelease: false
  requirement: &id004 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 3
        segments: 
        - 0
        version: "0"
  type: :development
  version_requirements: *id004
- !ruby/object:Gem::Dependency 
  name: syckle
  prerelease: false
  requirement: &id005 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        hash: 3
        segments: 
        - 0
        version: "0"
  type: :development
  version_requirements: *id005
description: Ratch is a Ruby-based batch scripting language. It's a DSL over regular Ruby to make the life of the batch script writter easier.
email: transfire@gmail.com
executables: 
- ratch
- ludo
extensions: []

extra_rdoc_files: 
- README.rdoc
files: 
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
- spec/01_shell.rdoc
- spec/02_script.rdoc
- spec/03_batch.rdoc
- spec/04_system.rdoc
- spec/applique/array.rb
- spec/applique/setup.rb
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
has_rdoc: true
homepage: http://rubyworks.github.org/ratch
licenses: 
- Apache 2.0
post_install_message: 
rdoc_options: 
- --title
- Ratch API
- --main
- README.rdoc
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
required_rubygems_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
requirements: []

rubyforge_project: ratch
rubygems_version: 1.3.7
signing_key: 
specification_version: 3
summary: Ruby-based Batch Scripting
test_files: 
- lib/ratch/core_ext/filetest.rb
