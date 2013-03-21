require 'test_helper'

class ConnectionTest < TestCase
  include Antfarm::Models

  test 'fails with no source present' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :conn, :source_layer3_interface => nil
    end

    assert !Fabricate.build(:conn, :source_layer3_interface => nil).valid?
  end

  test 'fails with no target present' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :conn, :target_layer3_interface => nil
    end

    assert !Fabricate.build(:conn, :target_layer3_interface => nil).valid?
  end
end
