require 'simplecov'
SimpleCov.start

require 'antfarm'

Antfarm::Initializer.run do |config|
  config.environment = 'test'
  config.log_level   = 'debug'
end

require 'minitest/autorun'
require 'fabrication'

class TestCase < MiniTest::Unit::TestCase
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\W/, '_')}", &block) if block
  end

  def setup
    ActiveRecord::Migration.suppress_messages do
      load 'antfarm/schema.rb'
    end
  end
end
