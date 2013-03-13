require 'antfarm'

load 'antfarm/schema.rb'

module Antfarm
  module CiscoRouter
    def self.registered(plugin)
      plugin.name = 'cisco-router'
      plugin.options = [{
        :name     => 'network',
        :type     => String,
        :required => true,
        :default  => '192.168.101.201',
        :accept   => ['192.168.101.201']
      }]
    end

    def run(opts = Hash.new)
      check_options(opts)
      puts self.plugin_module
      puts "#{@name} running!!!"
      puts opts.class
      puts opts[:network].class
      puts opts[:network]
    end
  end
end

plugin = Antfarm.register(Antfarm::CiscoRouter)
puts plugin
plugin = Antfarm.plugin('cisco-router')
puts plugin
puts plugin.plugin_module
plugin.run
#plugin.run(:network => '192.168.101.201')
