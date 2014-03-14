require 'test_helper'

class IPNetworkTest < TestCase
  include Antfarm::Models

  test 'layer 3 network created when not provided' do
    assert Fabricate :ipnet, :l3_net => nil
    assert Fabricate.build(:ipnet, :l3_net => nil).valid?
  end

  test 'layer 3 network provided is used for new IP network' do
    net = Fabricate :l3net
    assert net, Fabricate(:ipnet, :l3_net => net).l3_net
    assert net != Fabricate(:ipnet, :l3_net => nil).l3_net
  end

  test 'fails with no address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipnet, :address => nil
    end

    assert !Fabricate.build(:ipnet, :address => nil).valid?
  end

  test 'fails with loopback address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipnet, :address => '127.0.0.0/8'
    end

    assert !Fabricate.build(:ipnet, :address => '127.0.0.0/8').valid?
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipnet, :address => '276.87.355.0/24'
    end

    assert !Fabricate.build(:ipnet, :address => '276.87.355.0/24').valid?
  end

  test 'correctly sets network as private' do
    assert  Fabricate(:ipnet, :address => '192.168.101.0/24').private
    assert !Fabricate(:ipnet, :address => '207.65.45.0/24').private
  end

  test 'creates private network entry when private' do
    net = Fabricate(:ipnet, :address => '192.168.101.0/24')
    assert 'Private network for 192.168.101.0/24', net.private_network.description

    assert !Fabricate(:ipnet, :address => '207.65.45.0/24').private_network
  end
end
