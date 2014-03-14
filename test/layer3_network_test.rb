require 'test_helper'

class L3NetTest < TestCase
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
    net = Fabricate :l3net, :ip_net_attributes => { :address => '10.0.0.0/24' }
    assert_kind_of Antfarm::Models::IPNet, net.ip_net
    assert_equal   '10.0.0.0/24', net.ip_net.address
  end

  test 'addressed/containing search fails when no address given' do
    Fabricate :l3net, :ip_net_attributes => { :address => '10.0.0.0/24' }

    assert_raises(Antfarm::AntfarmError) do
      L3Net.network_addressed(nil)
    end

    assert_raises(Antfarm::AntfarmError) do
      L3Net.network_containing(nil)
    end

    assert_nil L3Net.network_addressed('10.0.1.0/24')
    assert_nil L3Net.network_containing('10.0.1.0/24')

    assert_kind_of Antfarm::Models::L3Net,
      L3Net.network_addressed('10.0.0.0/24')

    assert_kind_of Antfarm::Models::L3Net,
      L3Net.network_containing('10.0.0.0/24')

    assert_kind_of Antfarm::Models::L3Net,
      L3Net.network_containing('10.0.0.5')
  end

  test 'contained_within search fails when no address given' do
    Fabricate :l3net, :ip_net_attributes => { :address => '10.0.0.0/24' }

    assert_raises(Antfarm::AntfarmError) do
      L3Net.networks_contained_within(nil)
    end

    assert L3Net.networks_contained_within('10.0.1.0/24').empty?

    L3Net.networks_contained_within('10.0.0.0/23').each do |net|
      assert_kind_of Antfarm::Models::L3Net, net
      assert '10.0.0.0/24', net.ip_net.address
    end
  end

  test 'merging of subnetworks within a new, larger network' do
    assert_raises(Antfarm::AntfarmError) do
      L3Net.merge(nil)
    end

    net1  = Fabricate :l3net,   :ip_net_attributes => { :address => '10.0.0.0/23' }
    net2  = Fabricate :l3net,   :ip_net_attributes => { :address => '10.0.0.0/24' }
    iface = Fabricate :l3iface, :ip_if_attributes      => { :address => '10.0.0.1' },
                                :l3_net          => net2

    assert net2.ip_net, IPNet.find_by_address('10.0.0.0/24')

    assert net2, iface.l3_net
    L3Net.merge(net1)
    assert net1, iface.l3_net

    assert '10.0.0.0/23', L3Net.network_addressed('10.0.0.0/24')
    assert_nil IPNet.find_by_address('10.0.0.0/24')
  end

  test 'allows tags to be added via taggable association' do
    net = Fabricate :l3net

    assert net.tags.count.zero?
    net.tags.create(:name => 'Control Center')
    assert net.tags.count == 1
    assert net.tags.first.persisted?
    assert net.tags.first.name == 'Control Center'
    assert Tag.count == 1
  end
end
