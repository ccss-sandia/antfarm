module Antfarm
  module CiscoRouter
    def self.registered(plugin)
      plugin.name = 'cisco-router'
      plugin.info = {
        :desc   => 'Cisco 6500 router config parser',
        :author => 'Bryan T. Richardson'
      }
      plugin.options = [{
        :name     => 'network',
        :desc     => 'Network address',
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

Antfarm.register(Antfarm::CiscoRouter)
