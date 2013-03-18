require 'test_helper'

class PluginTest < TestCase
  test 'correct plugin is returned' do
    module Foo
      def self.registered(plugin)
        plugin.name = 'foo-tester'
      end

      def run(opts = Hash.new)
        return
      end
    end

    plugin = Antfarm.register(Foo)

    assert plugin, Antfarm.plugin('foo-tester')
  end

  test 'throws on duplicate plugin name' do
    module Bar
      def self.registered(plugin)
        plugin.name = 'bar-tester'
      end

      def run(opts = Hash.new)
        return
      end
    end

    Antfarm.register(Bar)

    module Sucka
      def self.registered(plugin)
        plugin.name = 'bar-tester'
      end

      def run(opts = Hash.new)
        return
      end
    end

    assert_raises(Antfarm::Plugin::NameException) do
      Antfarm.register(Sucka)
    end
  end

  test 'throws a registration exception' do
    module FooBarSucka
      def run(opts = Hash.new)
        return
      end
    end

    assert_raises(Antfarm::Plugin::RegistrationException) do
      Antfarm.register(FooBarSucka)
    end
  end

  test 'throws a run method exception' do
    module FooBar
      def self.registered(plugin)
        plugin.name = 'foo-bar-tester'
      end
    end

    assert_raises(Antfarm::Plugin::RunMethodException) do
      Antfarm.register(FooBar)
    end
  end

  test 'throws a registered options exception' do
    module RegisteredOptionsTester
      def self.registered(plugin)
        plugin.name = 'registered-options-tester'
      end

      def run(opts = Hash.new)
        check_options(opts)
        return true
      end
    end

    plugin = Antfarm.register(RegisteredOptionsTester)
    assert plugin.run
    assert_raises(Antfarm::Plugin::RegisteredOptionsException) do
      plugin.run({ :foo => 'bar' })
    end
  end

  test 'throws a runtime options exception' do
    module RuntimeOptionsTester
      def self.registered(plugin)
        plugin.name = 'runtime-options-tester'
        plugin.options = [{
          :name     => 'network',
          :type     => String,
          :required => true
        }]
      end

      def run(opts = Hash.new)
        check_options(opts)
        return true
      end
    end

    plugin = Antfarm.register(RuntimeOptionsTester)
    assert plugin.run(:network => '192.168.101.201')
    assert_raises(Antfarm::Plugin::RuntimeOptionsException) do
      plugin.run({ :foo => 'bar' })
    end
  end

  test 'does not throw a runtime options exception' do
    module RuntimeOptionsTester2
      def self.registered(plugin)
        plugin.name = 'runtime-options-tester-2'
        plugin.options = [{
          :name     => 'network',
          :type     => String,
          :required => true,
          :default  => '192.168.101.201'
        }]
      end

      def run(opts = Hash.new)
        check_options(opts)
        return true
      end
    end

    plugin = Antfarm.register(RuntimeOptionsTester2)
    assert plugin.run
  end

  test 'raises an error when options are of incorrect type' do
    module OptionTypeTester
      def self.registered(plugin)
        plugin.name = 'option-type-tester'
        plugin.options = [{
          :name     => 'network',
          :type     => String,
          :required => true
        }]
      end

      def run(opts = Hash.new)
        check_options(opts)
        return true
      end
    end

    plugin = Antfarm.register(OptionTypeTester)
    assert_raises(RuntimeError) do
      plugin.run({ :network => 5 })
    end
  end

  test 'raises an error when options are not within acceptable options' do
    module OptionAcceptableTester
      def self.registered(plugin)
        plugin.name = 'option-acceptable-tester'
        plugin.options = [{
          :name     => 'network',
          :type     => String,
          :required => true,
          :accept   => ['192.168.101.201']
        }]
      end

      def run(opts = Hash.new)
        check_options(opts)
        return true
      end
    end

    plugin = Antfarm.register(OptionAcceptableTester)
    assert_raises(RuntimeError) do
      plugin.run({ :network => '192.168.101.200' })
    end
  end
end
