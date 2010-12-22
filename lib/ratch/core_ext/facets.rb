# I know some people will be deterred by the dependency on Facets b/c they
# see it as a "heavy" dependency. But really that is far from true, consider
# the following libs are all that it used.

require 'facets/array/not_empty'
require 'facets/dir/multiglob'   # DEPRECATE b/c of new #glob.
require 'facets/module/basename'
require 'facets/module/alias_accessor'
require 'facets/kernel/ask'
require 'facets/kernel/silence' # FIXME

require 'facets/pathname'
require 'facets/filetest'
require 'facets/fileutils'

