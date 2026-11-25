require 'ratch/version'
require 'ratch/script'

# Utility extension modules, to include in a Shell subclass or extend a
# shell with. Each loads what it depends on only when it is used.
require 'ratch/utils/cli'
require 'ratch/utils/config'
require 'ratch/utils/zlib'
require 'ratch/utils/tar'
require 'ratch/utils/rdoc'
require 'ratch/utils/email'
require 'ratch/utils/xdg'
