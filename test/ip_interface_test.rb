require 'test_helper'

class IPInterfaceTest < TestCase
  include Antfarm::Models

  test 'fails with no layer 3 interface' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :layer3_interface => nil
    end

    assert !Fabricate.build(:ipiface, :layer3_interface => nil).valid?
  end

  test 'fails with no address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => nil
    end

    assert !Fabricate.build(:ipiface, :address => nil).valid?
  end

  test 'fails with loopback address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => '127.0.0.1'
    end

    assert !Fabricate.build(:ipiface, :address => '127.0.0.1').valid?
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => '276.87.355.4'
    end

    assert !Fabricate.build(:ipiface, :address => '276.87.355.4').valid?
  end

  test 'fails with duplicate public address' do
    Fabricate :ipiface, :address => '246.87.155.4'
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => '246.87.155.4'
    end
  end

  test 'creates IP network and merges networks and interfaces' do
    Fabricate :l3net, :ip_network_attributes => { :address => '192.168.101.0/29' }
    assert 1, Layer3Network.count

    iface = Fabricate :ipiface, :address => '192.168.101.4/24'

    assert 1, Layer3Network.count
    assert '192.168.101.0/24', Layer3Network.first.ip_network.address
    assert Layer3Network.first, iface.layer3_interface.layer3_network
  end
end
