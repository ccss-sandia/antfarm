################################################################################
#                                                                              #
# Copyright (2008-2014) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

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
        :name => 'device_types',
        :desc => 'Device types (separated by commas) to include',
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

      data  = { :nodes => nodes, :links => links }
      types = opts[:device_types].split(',')

      node_indexes = Hash.new
      net_indexes  = Hash.new

      Antfarm::Models::Layer3Network.all.each do |network|
        if opts[:include_nodes]
          display = true
        else
          display = false

          network.layer3_interfaces.each do |iface|
            node_type = iface.layer2_interface.node.device_type.split(' ')

            unless (types & node_type).empty?
              display = true
              break
            end
          end
        end

        if display
          net_indexes[network.id] = nodes.length
          nodes << { :name => "net-#{network.id}", :group => 'LAN', :label => network.ip_network.address }
        end
      end

      Antfarm::Models::Node.all.each do |node|
        node_type = node.device_type.split(' ')

        if opts[:include_nodes] or not (types & node_type).empty?
          node_indexes[node.id] = nodes.length
          nodes << { :name => "node-#{node.id}", :group => node.device_type, :label => node.name }

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
