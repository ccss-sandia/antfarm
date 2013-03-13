require 'helper'

class IpInterfaceTest < TestCase
  include Antfarm::Models

  test 'fails with no layer 3 interface' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IpInterface.create!(
        :address => '192.168.101.101'
      )
    end

    assert !IpInterface.create(
      :address => '192.168.101.101'
    ).valid?
  end

  test 'fails with no address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IpInterface.create!(
        :layer3_interface => Layer3Interface.last
      )
    end

    assert !IpInterface.create(
      :layer3_interface => Layer3Interface.last
    ).valid?
  end

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      IpInterface.create!(
        :layer3_interface => Layer3Interface.last,
        :address => '276.87.355.4'
      )
    end

    assert !IpInterface.create(
      :layer3_interface => Layer3Interface.last,
      :address => '276.87.355.4'
    ).valid?
  end
end
