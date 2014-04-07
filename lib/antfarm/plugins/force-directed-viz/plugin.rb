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

require 'slim'
require 'tempfile'

module Antfarm
  module ForceDirectedViz
    class Env
      attr_accessor :data
    end

    def self.registered(plugin)
      plugin.name = 'force-directed-viz'
      plugin.info = {
        :desc   => 'Visualize network data in DB as a force-directed graph w/ D3js',
        :author => 'Bryan T. Richardson'
      }
      plugin.options = [{
        :name    => 'file_name',
        :desc    => 'Name to use for output file (will land in ~/.antfarm/tmp)',
        :type    => String,
        :default => 'fdv.html'
      },
      {
        :name     => 'device_types',
        :desc     => 'Device types (separated by commas) to include',
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

      Antfarm::Models::L3Net.all.each do |network|
        if opts[:include_nodes]
          display = true
        else
          display = false

          network.l3_ifs.each do |iface|
            node_type = iface.l2_if.node.device_type.split(' ')

            unless (types & node_type).empty?
              display = true
              break
            end
          end
        end

        if display
          net_indexes[network.id] = nodes.length
          nodes << { :name => "net-#{network.id}", :group => 'LAN', :label => network.ip_net.address }
        end
      end

      Antfarm::Models::Node.all.each do |node|
        node_type = node.device_type.split(' ')

        if opts[:include_nodes] or not (types & node_type).empty?
          node_indexes[node.id] = nodes.length
          nodes << { :name => "node-#{node.id}", :group => node.device_type, :label => node.name }

          node.l3_ifs.each do |iface|
            links << { :source => node_indexes[node.id], :target => net_indexes[iface.l3_net.id], :value => 1 }
          end
        end
      end

      env      = Env.new
      env.data = data.to_json

      # Alternative to using DATA, since it won't work in required files...
      # TODO: turn this into a helper available from the Plugin parent class
      template = File.read(__FILE__) =~ /^__END__\n/ && $' || ''
      content  = Slim::Template.new { template }

      File.open("#{Antfarm::Helpers.user_tmp_dir}/#{opts[:file_name]}", 'w') do |f|
        f.write(content.render(env))
      end

      # TODO: how to make this more cross-platform... Launchy gem perhaps?!
      `open #{Antfarm::Helpers.user_tmp_dir}/#{opts[:file_name]}`
    end
  end
end

Antfarm.register(Antfarm::ForceDirectedViz)

__END__

doctype html
html
  head
    title Force Directed Graph
    meta  charset="UTF-8"
    css:
      .node {
        stroke: #fff;
        stroke-width: 1.5px;
      }

      .link {
        stroke: #999;
        stroke-opacity: .6;
      }

  body
    script src="http://d3js.org/d3.v3.min.js"

    javascript:
      var width = 800, height = 500;

      var color = function(group) {
        if(group == 'host') {
          return 'red';
        } else if(group == 'router') {
          return 'blue';
        } else if(group == 'LAN') {
          return 'green';
        }
      };

      var force = d3.layout.force()
        .charge(-120)
        .linkDistance(30)
        .size([width, height]);

      var svg = d3.select("body").append("svg")
        .attr("width", width)
        .attr("height", height);

      var graph = #{{data}}

      force.nodes(graph.nodes)
        .links(graph.links)
        .start();

      var link = svg.selectAll(".link")
        .data(graph.links)
        .enter().append("line")
        .attr("class", "link")
        .style("stroke-width", function(d) { return Math.sqrt(d.value); });

      var node = svg.selectAll(".node")
        .data(graph.nodes)
        .enter().append("circle")
        .attr("class", "node")
        .attr("r", 5)
        .style("fill", function(d) { return color(d.group); });

      node.append("title")
        .text(function(d) { return d.name; });

      force.on("tick", function() {
        link.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });

        node.attr("cx", function(d) { return d.x; })
          .attr("cy", function(d) { return d.y; });
      });
