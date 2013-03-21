require 'test_helper'

class ServiceTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Service.create!
    end

    assert !Service.create.valid?
  end

  test 'fails with no node present' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :service, :node => nil
    end

    assert !Fabricate.build(:service, :node => nil).valid?
  end

  test 'correctly clamps certainty factor' do
    service = Fabricate :service, :certainty_factor => 1.15
    assert_equal 1.0, service.certainty_factor
    service = Fabricate :service
    assert_equal 0.5, service.certainty_factor
    service = Fabricate :service, :certainty_factor => -1.15
    assert_equal -1.0, service.certainty_factor
  end
end
