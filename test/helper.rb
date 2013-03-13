unless Object.const_defined? 'Antfarm'
  $:.unshift File.expand_path('../lib', __FILE__)
  require 'antfarm'
end

Antfarm::Initializer.run do |config|
  config.environment = :test
  config.log_level   = :debug
end

require 'minitest/autorun'

class TestCase < MiniTest::Unit::TestCase
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\W/, '_')}", &block) if block
  end
end
