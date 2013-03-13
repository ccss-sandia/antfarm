require 'helper'

class NodeTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Node.create!
    end

    assert !Node.create.valid?
  end

  test 'correctly clamps certainty factor' do
    node = Node.create :certainty_factor => 1.15
    assert_equal 1.0, node.certainty_factor
    node = Node.create :certainty_factor => 0.15
    assert_equal 0.15, node.certainty_factor
    node = Node.create :certainty_factor => -1.15
    assert_equal -1.0, node.certainty_factor
  end

  test 'search fails when no name given' do
    Node.create :certainty_factor => 0.5, :name => 'test-node'

    assert_raises(ArgumentError) do
      Node.node_named(nil)
    end

    assert_nil Node.node_named('foo')

    Node.node_named('test-node').each do |node|
      assert_kind_of Antfarm::Models::Node, node
    end
  end

  test 'search fails when no device type given' do
    Node.create :certainty_factor => 0.5, :device_type => 'RTU'

    assert_raises(ArgumentError) do
      Node.nodes_of_device_type(nil)
    end

    assert_nil     Node.nodes_of_device_type('foo')
    assert_kind_of Array, Node.nodes_of_device_type('RTU')
  end
end
