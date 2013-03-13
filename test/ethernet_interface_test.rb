require 'helper'

class EthernetInterfaceTest < TestCase
  include Antfarm::Models

  test 'fails with no layer 2 interface' do
    assert_raises(ActiveRecord::RecordInvalid) do
      EthernetInterface.create!(
        :address => '00:00:00:00:00:01'
      )
    end

    assert !EthernetInterface.create(
      :address => '00:00:00:00:00:01'
    ).valid?
  end

  test 'fails with no address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      EthernetInterface.create!(
        :layer2_interface => Layer2Interface.last
      )
    end

    assert !EthernetInterface.create(
      :layer2_interface => Layer2Interface.last
    ).valid?
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      EthernetInterface.create!(
        :layer2_interface => Layer2Interface.last,
        :address => '00:00:00:00:00:0Z'
      )
    end

    assert !EthernetInterface.create(
      :layer2_interface => Layer2Interface.last,
      :address => '00:00:00:00:00:0Z'
    ).valid?
  end
end
