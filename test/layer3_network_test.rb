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

  test 'search fails when no address given' do
    Fabricate :l3net, :ip_network_attributes => { :address => '10.0.0.0/24' }
    assert_raises(ArgumentError) do
      Layer3Network.network_addressed(nil)
    end

    assert_nil     Layer3Network.network_addressed('10.0.1.0/24')
    assert_kind_of Antfarm::Models::Layer3Network,
      Layer3Network.network_addressed('10.0.0.0/24')
  end
end
