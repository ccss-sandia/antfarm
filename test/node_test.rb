require 'test_helper'

class NodeTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Node.create!
    end

    assert !Node.create.valid?
  end

  test 'correctly clamps certainty factor' do
    node = Fabricate :node, :certainty_factor => 1.15
    assert_equal 1.0, node.certainty_factor
    node = Fabricate :node
    assert_equal 0.5, node.certainty_factor
    node = Fabricate :node, :certainty_factor => -1.15
    assert_equal -1.0, node.certainty_factor
  end

  test 'search fails when no name given' do
    Fabricate :node

    assert_raises(Antfarm::AntfarmError) do
      Node.node_named(nil)
    end

    assert_nil Node.node_named('foo')

    Node.node_named('test-node').each do |node|
      assert_kind_of Antfarm::Models::Node, node
    end
  end

  test 'search fails when no device type given' do
    Fabricate :node

    assert_raises(Antfarm::AntfarmError) do
      Node.nodes_of_device_type(nil)
    end

    assert_nil     Node.nodes_of_device_type('foo')
    assert_kind_of Array, Node.nodes_of_device_type('RTU')
  end

  test 'creates full stack of records using attributes' do
    Fabricate :node,
      :l2_ifs_attributes => [{
        :certainty_factor => 1.0, :media_type => 'Ethernet',
        :layer3_interfaces_attributes => [{ :certainty_factor => 1.0, :protocol => 'IP',
          :ip_interface_attributes => { :address => '192.168.101.5/24' }
        }]
      }]

    iface = Layer3Interface.interface_addressed('192.168.101.5')
    net   = Layer3Network.network_addressed('192.168.101.0/24')

    assert iface
    assert net

    assert net == iface.layer3_network
  end

  test 'allows tags to be added via taggable association' do
    node = Fabricate :node

    assert node.tags.count.zero?
    node.tags.create(:name => 'Modbus TCP Master')
    assert node.tags.count == 1
    assert node.tags.first.persisted?
    assert node.tags.first.name == 'Modbus TCP Master'
    assert Tag.count == 1
  end
end
