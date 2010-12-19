require 'folio/fileobject'

module Folio

  # Device base class
  class Device < FileObject

    def initialize(path)
      raise 'Devices not yet supported.'
    end

  end

  # Character device
  class CharacterDevice < Device

    def chardev? ; true ; end

  end

  # Block device
  class BlockDevice < Device

    def blockdev? ; true ; end

  end

end

