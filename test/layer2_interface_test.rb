require 'test_helper'

class Layer2InterfaceTest < TestCase
  include Antfarm::Models

  test 'fails with no node' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :l2iface, :node => nil
    end

    assert !Fabricate.build(:l2iface, :node => nil).valid?
  end

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :l2iface, :certainty_factor => nil
    end

    assert !Fabricate.build(:l2iface, :certainty_factor => nil).valid?
  end

  test 'correctly clamps certainty factor' do
    iface = Fabricate :l2iface, :certainty_factor => 1.15
    assert_equal 1.0, iface.certainty_factor
    iface = Fabricate :l2iface
    assert_equal 0.5, iface.certainty_factor
    iface = Fabricate :l2iface, :certainty_factor => -1.15
    assert_equal -1.0, iface.certainty_factor
  end

  test 'creates ethernet iface using attributes' do
    iface = Fabricate :l2iface, :ethernet_interface_attributes => { :address => 'AB:00:00:00:00:00' }
    assert_kind_of Antfarm::Models::EthernetInterface, iface.ethernet_interface
    assert_equal   'AB:00:00:00:00:00', iface.ethernet_interface.address
  end

  test 'search fails when no address given' do
    Fabricate :l2iface, :ethernet_interface_attributes => { :address => 'AB:00:00:00:00:00' }
    assert_raises(Antfarm::AntfarmError) do
      Layer2Interface.interface_addressed(nil)
    end

    assert_nil     Layer2Interface.interface_addressed('00:00:00:00:00:00')
    assert_kind_of Antfarm::Models::Layer2Interface,
      Layer2Interface.interface_addressed('AB:00:00:00:00:00')
  end

  test 'allows tags to be added via taggable association' do
    iface = Fabricate :l2iface

    assert iface.tags.count.zero?
    iface.tags << Tag.new(:name => 'SEL')
    assert iface.tags.count == 1
    assert iface.tags.first.name == 'SEL'
  end
end
