var width  = 2500,
    height = 2000;

var nodes = [],
    links = [];

var svg = d3.select('#graph').append('svg')
    .attr('width', width)
    .attr('height', height);

var force = d3.layout.force()
    .gravity(.05)
    .distance(100)
    .charge(-100)
    .size([width, height]);

force.nodes(nodes)
     .links(links);

force.on("tick", function() {
  svg.selectAll(".link")
    .attr("x1", function(d) { return d.source.x; })
    .attr("y1", function(d) { return d.source.y; })
    .attr("x2", function(d) { return d.target.x; })
    .attr("y2", function(d) { return d.target.y; });

  svg.selectAll(".node")
    .attr('transform', function(d) { return 'translate(' + d.x + ',' + d.y + ')'; });
});

function addData(json) {
  if (typeof json.node !== 'undefined') {
    nodes.push(json.node);
  }

  if (typeof json.link !== 'undefined') {
    links.push(json.link);
  }

  force.start();

  var link = svg.selectAll(".link")
      .data(links)
      .enter().append("line")
      .attr("class", "link");

  var node = svg.selectAll(".node")
      .data(nodes)
      .enter().append("g")
      .attr("class", "node")
      .call(force.drag);

  node.append('circle')
    .attr("r", 5)
    .style("fill", function(d) {
      if (d.group == 'LAN') { return 'black'; }
      else if (d.group == 'Cisco PIX/ASA') { return 'red'; }
      else { return 'green'; }
    });

  node.append("text").text(function(d) { return d.label; });
}
