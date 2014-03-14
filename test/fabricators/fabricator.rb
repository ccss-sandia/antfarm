Fabricator(:node, :class_name => Antfarm::Models::Node) do
  name             'test-node'
  certainty_factor 0.5
  device_type      'RTU'
end

Fabricator(:l2iface, :class_name => Antfarm::Models::L2If) do
  node
  certainty_factor 0.5
end

Fabricator(:ethiface, :class_name => Antfarm::Models::EthIf) do
  l2_if   :fabricator => :l2iface
  address '00:00:00:00:00:01'
end

Fabricator(:l3iface, :class_name => Antfarm::Models::L3If) do
  l2_if            :fabricator => :l2iface
  certainty_factor 0.5
end

Fabricator(:ipiface, :class_name => Antfarm::Models::IPIf) do
  l3_if   :fabricator => :l3iface
  address '10.0.0.1'
end

Fabricator(:l3net, :class_name => Antfarm::Models::L3Net) do
  certainty_factor 0.5
end

Fabricator(:ipnet, :class_name => Antfarm::Models::IPNetwork) do
  l3_net  :fabricator => :l3net
  address '10.0.0.0/24'
end

Fabricator(:action, :class_name => Antfarm::Models::Action) do
  tool        'nmap'
  description 'network scanner'
end

Fabricator(:os, :class_name => Antfarm::Models::OperatingSystem) do
  node             :fabricator => :node
  certainty_factor 0.5
end

Fabricator(:service, :class_name => Antfarm::Models::Service) do
  node             :fabricator => :node
  certainty_factor 0.5
end

Fabricator(:conn, :class_name => Antfarm::Models::Connection) do
  src      :fabricator => :l3iface
  dst      :fabricator => :l3iface
  dst_port 502
end
