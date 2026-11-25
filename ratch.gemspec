require_relative 'lib/ratch/version'

Gem::Specification.new do |s|
  s.name        = 'ratch'
  s.version     = Ratch::VERSION
  s.summary     = 'A file system shell in code, and batch scripts in Ruby'
  s.description = 'Ratch provides a Shell object that stands at a directory and works from there, ' \
                  'as a shell prompt does: file tests, file operations, globbing and system commands, ' \
                  'with dry-run and trace modes. Batch does the same over a list of files, and the ' \
                  'ratch command runs a Ruby script inside a Shell.'

  s.authors  = ['Trans']
  s.email    = ['transfire@gmail.com']
  s.homepage = 'https://github.com/rubyworks/ratch'
  s.license  = 'Apache-2.0'

  s.metadata = {
    'homepage_uri'      => s.homepage,
    'source_code_uri'   => 'https://github.com/rubyworks/ratch',
    'bug_tracker_uri'   => 'https://github.com/rubyworks/ratch/issues',
    'changelog_uri'     => 'https://github.com/rubyworks/ratch/blob/master/HISTORY.rdoc',
    'documentation_uri' => 'https://rubydoc.info/gems/ratch'
  }

  s.required_ruby_version = '>= 3.1'

  s.files = Dir[
    'lib/**/*.rb', 'bin/*',
    'README.rdoc', 'HISTORY.rdoc', 'LICENSE.txt'
  ]
  s.bindir           = 'bin'
  s.executables      = ['ratch', 'ludo']
  s.require_paths    = ['lib']
  s.extra_rdoc_files = ['README.rdoc', 'HISTORY.rdoc', 'LICENSE.txt']

  s.add_dependency 'facets', '>= 4.0'

  # For EmailUtils; a bundled gem, not a default one, since Ruby 3.1.
  s.add_development_dependency 'net-smtp'

  s.add_development_dependency 'rake', '>= 13'
  s.add_development_dependency 'rubytest', '>= 0.11.1'
  s.add_development_dependency 'spectrum', '>= 0.2'
  s.add_development_dependency 'assay', '>= 0.5.1'
end
