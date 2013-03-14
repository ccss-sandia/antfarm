require 'helper'

class IpInterfaceTest < TestCase
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

  test 'fails with invalid address' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :ipiface, :address => '276.87.355.4'
    end

    assert !Fabricate.build(:ipiface, :address => '276.87.355.4').valid?
  end
end
