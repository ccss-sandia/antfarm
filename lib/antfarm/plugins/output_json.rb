module Antfarm
  module OutputJson
    def self.registered(plugin)
      plugin.name = 'output-json'
      plugin.info = {
        :desc   => 'Output network graph to JSON',
        :author => 'Bryan T. Richardson'
      }
      plugin.options = [{
        :name     => 'output_file',
        :desc     => 'File to output JSON to',
        :type     => String,
        :required => true
      },
      {
        :name => 'include_nodes',
        :desc => 'Include normal nodes in output'
      }]
    end

    def run(opts = Hash.new)
      check_options(opts)

      require 'json'

      nodes = Array.new
      links = Array.new

      data = { :nodes => nodes, :links => links }

      node_indexes = Hash.new
      net_indexes  = Hash.new

      Antfarm::Models::Layer3Network.all.each do |network|
        net_indexes[network.id] = nodes.length
        nodes << { :name => network.id, :group => 'LAN', :label => network.ip_network.address }
      end

      Antfarm::Models::Node.all.each do |node|
        if opts[:include_nodes] or node.device_type == 'Cisco PIX/ASA'
          node_indexes[node.id] = nodes.length
          nodes << { :name => node.id, :group => node.device_type, :label => node.name }

          node.layer3_interfaces.each do |iface|
            links << { :source => node_indexes[node.id], :target => net_indexes[iface.layer3_network.id], :value => 1 }
          end
        end
      end

      File.open(opts[:output_file], 'w') do |f|
        f.write JSON.pretty_generate(data)
      end
    end
  end
end

Antfarm.register(Antfarm::OutputJson)
