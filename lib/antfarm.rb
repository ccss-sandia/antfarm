module Antfarm
  class << self
    def root
      return File.expand_path(File.dirname(__FILE__) + '/..')
    end

    def initialize!
      unless initialized?
        require 'antfarm/initializer'
        Antfarm::Initializer.run(:init)
      end
    end

    def initialized?
      defined? Antfarm::Initializer
    end
  end
end

Antfarm.initialize!
