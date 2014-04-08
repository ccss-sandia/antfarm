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

require 'launchy'
require 'slim'

module Antfarm
  module ChordViz
    class Env
      attr_accessor :nodes
      attr_accessor :matrix
    end

    def self.registered(plugin)
      plugin.name = 'chord-viz'
      plugin.info = {
        :desc   => 'Visualize network traffic in DB as a diagram graph w/ D3js',
        :author => 'Bryan T. Richardson'
      }
      plugin.options = [{
        :name    => 'file_name',
        :desc    => 'Name to use for output file (will land in ~/.antfarm/tmp)',
        :type    => String,
        :default => 'chord.html'
      }]
    end

    def run(opts = Hash.new)
      check_options(opts)

      csv = Hash.new # poor man's unique Set...

      Antfarm::Models::Connection.all.each do |conn|
        csv[conn.src_id] = true
        csv[conn.dst_id] = true
      end

      ifaces = csv.keys.sort
      matrix = Array.new(ifaces.size) { Array.new(ifaces.size, 0) }

      Antfarm::Models::Connection.all.each do |conn|
        i = ifaces.index(conn.src_id)
        j = ifaces.index(conn.dst_id)
        matrix[i][j] += 1
      end

      nodes = Array.new(ifaces.size)
      ifaces.each_with_index do |iface,index|
        name = Antfarm::Models::L3If.find(iface).l2_if.node.id
        nodes[index] = { :name => name, :color => random_color_code }
      end

      env        = Env.new
      env.nodes  = nodes.to_json
      env.matrix = matrix.to_json

      # Alternative to using DATA, since it won't work in required files...
      # TODO: turn this into a helper available from the Plugin parent class
      template = File.read(__FILE__) =~ /^__END__\n/ && $' || ''
      content  = Slim::Template.new { template }

      File.open("#{Antfarm::Helpers.user_tmp_dir}/#{opts[:file_name]}", 'w') do |f|
        f.write(content.render(env))
      end

      # TODO: how to make this more cross-platform... Launchy gem perhaps?!
      Launchy.open("#{Antfarm::Helpers.user_tmp_dir}/#{opts[:file_name]}")
    end

    def random_color_code
      lum, ary = 0, []

      while lum < 128
       ary = (1..3).collect {rand(256)}
       lum = ary[0]*0.2126 + ary[1]*0.7152 + ary[2]*0.0722
      end

      return "##{ary.collect { |e| e.to_s(16) }.join}"
    end
  end
end

Antfarm.register(Antfarm::ChordViz)

__END__

<!-- D3js example taken from http://bost.ocks.org/mike/uberdata/ -->
doctype html
html
  head
    title Chord Diagram
    meta  charset="UTF-8"
    css:
      #circle circle {
        fill: none;
        pointer-events: all;
      }

      .group path {
        fill-opacity: .5;
      }

      path.chord {
        stroke: #000;
        stroke-width: .25px;
      }

      #circle:hover path.fade {
        display: none;
      }

  body
    script src="http://d3js.org/d3.v3.min.js"

    javascript:
      var width  = 720,
          height = 720,
          outerRadius = Math.min(width, height) / 2 - 10,
          innerRadius = outerRadius - 24;

      var nodes  = #{{nodes}};
      var matrix = #{{matrix}};

      var formatPercent = d3.format(".1%");

      var arc = d3.svg.arc()
          .innerRadius(innerRadius)
          .outerRadius(outerRadius);

      var layout = d3.layout.chord()
          .padding(.04)
          .sortSubgroups(d3.descending)
          .sortChords(d3.ascending);

      var path = d3.svg.chord()
          .radius(innerRadius);

      var svg = d3.select("body").append("svg")
          .attr("width", width)
          .attr("height", height)
          .append("g")
          .attr("id", "circle")
          .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

      svg.append("circle")
          .attr("r", outerRadius);

      // Compute the chord layout.
      layout.matrix(matrix);

      // Add a group per neighborhood.
      var group = svg.selectAll(".group")
          .data(layout.groups)
          .enter().append("g")
          .attr("class", "group")
          .on("mouseover", mouseover);

      // Add the group arc.
      var groupPath = group.append("path")
          .attr("id", function(d, i) { return "group" + i; })
          .attr("d", arc)
          .style("fill", function(d, i) { return nodes[i].color; });

      // Add a text label.
      var groupText = group.append("text")
          .attr("x", 6)
          .attr("dy", 15);

      groupText.append("textPath")
          .attr("xlink:href", function(d, i) { return "#group" + i; })
          .text(function(d, i) { return nodes[i].name; });

      // Remove the labels that don't fit. :(
      groupText.filter(function(d, i) { return groupPath[0][i].getTotalLength() / 2 - 16 < this.getComputedTextLength(); })
          .remove();

      // Add the chords.
      var chord = svg.selectAll(".chord")
          .data(layout.chords)
          .enter().append("path")
          .attr("class", "chord")
          .style("fill", function(d) { return nodes[d.source.index].color; })
          .attr("d", path);

      function mouseover(d, i) {
        chord.classed("fade", function(p) {
          return p.source.index != i
              && p.target.index != i;
        });
      }
