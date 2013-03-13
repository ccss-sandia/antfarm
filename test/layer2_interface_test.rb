require 'helper'

class Layer2InterfaceTest < TestCase
  include Antfarm::Models

  test 'fails with no node' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Layer2Interface.create! :certainty_factor => 0.5
    end

    assert !Layer2Interface.create(:certainty_factor => 0.5).valid?
  end

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Layer2Interface.create!(
        :node => Node.create(:certainty_factor => 0.5)
      )
    end

    assert !Layer2Interface.create(
      :node => Node.create(:certainty_factor => 0.5)
    ).valid?
  end

  test 'correctly clamps certainty factor' do
    iface = Layer2Interface.create(
      :node => Node.create(:certainty_factor => 0.5),
      :certainty_factor => 1.15
    )
    assert_equal 1.0, iface.certainty_factor
    iface = Layer2Interface.create(
      :node => Node.create(:certainty_factor => 0.5),
      :certainty_factor => 0.15
    )
    assert_equal 0.15, iface.certainty_factor
    iface = Layer2Interface.create(
      :node => Node.create(:certainty_factor => 0.5),
      :certainty_factor => -1.15
    )
    assert_equal -1.0, iface.certainty_factor
  end

  test 'creates ethernet iface using attributes' do
    iface = Layer2Interface.create(
      :node => Node.create(:certainty_factor => 0.5),
      :certainty_factor => -1.15,
      :ethernet_interface_attributes => { :address => 'AB:00:00:00:00:00' }
    )

    assert_kind_of Antfarm::Models::EthernetInterface, iface.ethernet_interface
    assert_equal   'AB:00:00:00:00:00', iface.ethernet_interface.address
  end

  test 'search fails when no address given' do
    Layer2Interface.create(
      :node => Node.create(:certainty_factor => 0.5),
      :certainty_factor => -1.15,
      :ethernet_interface_attributes => { :address => '00:00:00:00:00:AB' }
    )

    assert_raises(ArgumentError) do
      Layer2Interface.interface_addressed(nil)
    end

    assert_nil     Layer2Interface.interface_addressed('00:00:00:00:00:00')
    assert_kind_of Antfarm::Models::Layer2Interface,
      Layer2Interface.interface_addressed('00:00:00:00:00:AB')
  end
end
