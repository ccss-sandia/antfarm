require 'helper'

class Layer3NetworkTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :l3net, :certainty_factor => nil
    end

    assert !Fabricate.build(:l3net, :certainty_factor => nil).valid?
  end

  test 'correctly clamps certainty factor' do
    net = Fabricate :l3net, :certainty_factor => 1.15
    assert_equal 1.0, net.certainty_factor
    net = Fabricate :l3net
    assert_equal 0.5, net.certainty_factor
    net = Fabricate :l3net, :certainty_factor => -1.15
    assert_equal -1.0, net.certainty_factor
  end

  test 'creates IP network using attributes' do
    net = Fabricate :l3net, :ip_network_attributes => { :address => '10.0.0.0/24' }
    assert_kind_of Antfarm::Models::IpNetwork, net.ip_network
    assert_equal   '10.0.0.0/24', net.ip_network.address
  end

  test 'addressed/containing search fails when no address given' do
    Fabricate :l3net, :ip_network_attributes => { :address => '10.0.0.0/24' }

    assert_raises(ArgumentError) do
      Layer3Network.network_addressed(nil)
    end

    assert_raises(ArgumentError) do
      Layer3Network.network_containing(nil)
    end

    assert_nil Layer3Network.network_addressed('10.0.1.0/24')
    assert_nil Layer3Network.network_containing('10.0.1.0/24')

    assert_kind_of Antfarm::Models::Layer3Network,
      Layer3Network.network_addressed('10.0.0.0/24')

    assert_kind_of Antfarm::Models::Layer3Network,
      Layer3Network.network_containing('10.0.0.0/24')
  end

  test 'contained_within search fails when no address given' do
    Fabricate :l3net, :ip_network_attributes => { :address => '10.0.0.0/24' }

    assert_raises(ArgumentError) do
      Layer3Network.networks_contained_within(nil)
    end

    assert Layer3Network.networks_contained_within('10.0.1.0/24').empty?

    Layer3Network.networks_contained_within('10.0.0.0/23').each do |net|
      assert_kind_of Antfarm::Models::Layer3Network, net
      assert '10.0.0.0/24', net.ip_network.address
    end
  end

  test 'merging of subnetworks within a new, larger network' do
    assert_raises(ArgumentError) do
      Layer3Network.merge(nil)
    end

    net1  = Fabricate :l3net,   :ip_network_attributes   => { :address => '10.0.0.0/23' }
    net2  = Fabricate :l3net,   :ip_network_attributes   => { :address => '10.0.0.0/24' }
    iface = Fabricate :l3iface, :ip_interface_attributes => { :address => '10.0.0.1' },
                                :layer3_network          => net2

    assert net2.ip_network, IpNetwork.find_by_address('10.0.0.0/24')

    assert net2, iface.layer3_network
    Layer3Network.merge(net1)
    assert net1, iface.layer3_network

    assert '10.0.0.0/23', Layer3Network.network_addressed('10.0.0.0/24')
    assert_nil IpNetwork.find_by_address('10.0.0.0/24')
  end
end
