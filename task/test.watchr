# Run me with:
#   $ watchr task/test.watchr

# --------------------------------------------------
# Rules
# --------------------------------------------------
watch('^test.*/case_.*\.rb')  { |m| ko m[0] }

watch( '^lib/(.*)\.rb') do |m|
  dir, file  = File.split(m[1])
  dir = '' if dir == '.'
  ko File.join('test', dir, "case_#{file}.rb")
end

#watch( '^test/helper\.rb'              )  { ko tests }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
Signal.trap('QUIT') { ko tests  }   # Ctrl-\
Signal.trap('INT' ) { abort("\n") } # Ctrl-C

# --------------------------------------------------
# Helpers
# --------------------------------------------------
def ko(*paths)
  run "ko #{gem_opt} -Ilib:test #{paths.flatten.join(' ')}"
end

def tests
  Dir['test/**/*_case.rb']
end

def run( cmd )
  puts   cmd
  system cmd
end

def gem_opt
  defined?(Gem) ? "-rubygems" : ""
end
