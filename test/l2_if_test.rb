require 'test_helper'

class L2IfTest < TestCase
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
    iface = Fabricate :l2iface, :eth_if_attributes => { :address => 'AB:00:00:00:00:00' }
    assert_kind_of Antfarm::Models::EthIf, iface.eth_if
    assert_equal   'AB:00:00:00:00:00', iface.eth_if.address
  end

  test 'search fails when no address given' do
    Fabricate :l2iface, :eth_if_attributes => { :address => 'AB:00:00:00:00:00' }
    assert_raises(Antfarm::AntfarmError) do
      L2If.interface_addressed(nil)
    end

    assert_nil     L2If.interface_addressed('00:00:00:00:00:00')
    assert_kind_of Antfarm::Models::L2If,
      L2If.interface_addressed('AB:00:00:00:00:00')
  end

  test 'allows tags to be added via taggable association' do
    iface = Fabricate :l2iface

    assert iface.tags.count.zero?
    iface.tags.create(:name => 'SEL')
    assert iface.tags.count == 1
    assert iface.tags.first.persisted?
    assert iface.tags.first.name == 'SEL'
    assert Tag.count == 1
  end
end
