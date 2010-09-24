module Antfarm
  module CLI
    MAJOR = 0
    MINOR = 5
    BUG   = 0

    def self.version
      return "#{MAJOR}.#{MINOR}.#{BUG}"
    end
  end
end
