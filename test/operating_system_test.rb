require 'test_helper'

class OperatingSystemTest < TestCase
  include Antfarm::Models

  test 'fails with no certainty factor' do
    assert_raises(ActiveRecord::RecordInvalid) do
      OperatingSystem.create!
    end

    assert !OperatingSystem.create.valid?
  end

  test 'fails with no node present' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :os, :node => nil
    end

    assert !Fabricate.build(:os, :node => nil).valid?
  end

  test 'correctly clamps certainty factor' do
    os = Fabricate :os, :certainty_factor => 1.15
    assert_equal 1.0, os.certainty_factor
    os = Fabricate :os
    assert_equal 0.5, os.certainty_factor
    os = Fabricate :os, :certainty_factor => -1.15
    assert_equal -1.0, os.certainty_factor
  end
end
