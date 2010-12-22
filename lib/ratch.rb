module Ratch
  # Access to project metadata.
  def self.metadata
    @metadata ||= (
      require 'yaml'
      YAML.load(File.dirname(__FILE__) + '/ratch.yml')
    )
  end

  # Access to project metadata via constants.
  def self.const_missing(name)
    metadata[name.to_s.downcase] || super(name)
  end

  # TODO: Only here b/c of issue with Ruby 1.8.x.
  VERSION = metadata['version']
end

require 'ratch/script'

# Load utility extension modules.
require 'ratch/utils/cli'
require 'ratch/utils/pom'
require 'ratch/utils/rdoc'
#require 'ratch/utils/email'
#require 'ratch/utils/tar'
#require 'ratch/utils/zlib'

