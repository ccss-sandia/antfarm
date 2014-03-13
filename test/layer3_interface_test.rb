require 'test_helper'

class Layer3InterfaceTest < TestCase
  include Antfarm::Models

  test 'fails with no layer 2 interface' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :l3iface, :layer2_interface => nil
    end

    assert !Fabricate.build(:l3iface, :layer2_interface => nil).valid?
  end

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :l3iface, :certainty_factor => nil
    end

    assert !Fabricate.build(:l3iface, :certainty_factor => nil).valid?
  end

  test 'correctly clamps certainty factor' do
    iface = Fabricate :l3iface, :certainty_factor => 1.15
    assert_equal 1.0, iface.certainty_factor
    iface = Fabricate :l3iface
    assert_equal 0.5, iface.certainty_factor
    iface = Fabricate :l3iface, :certainty_factor => -1.15
    assert_equal -1.0, iface.certainty_factor
  end

  test 'creates IP iface using attributes' do
    iface = Fabricate :l3iface, :ip_interface_attributes => { :address => '10.0.0.1' }
    assert_kind_of Antfarm::Models::IPInterface, iface.ip_interface
    assert_equal   '10.0.0.1', iface.ip_interface.address
  end

  test 'search fails when no address given' do
    Fabricate :l3iface, :ip_interface_attributes => { :address => '10.0.0.1' }
    assert_raises(Antfarm::AntfarmError) do
      Layer3Interface.interface_addressed(nil)
    end

    assert_nil     Layer3Interface.interface_addressed('10.0.0.0')
    assert_kind_of Antfarm::Models::Layer3Interface,
      Layer3Interface.interface_addressed('10.0.0.1')
  end

  test 'allows tags to be added via taggable association' do
    iface = Fabricate :l3iface

    assert iface.tags.count.zero?
    iface.tags.create(:name => 'USA')
    assert iface.tags.count == 1
    assert iface.tags.first.persisted?
    assert iface.tags.first.name == 'USA'
    assert Tag.count == 1
  end
end
