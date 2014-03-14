require 'test_helper'

class ConnectionTest < TestCase
  include Antfarm::Models

  test 'fails with no source present' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :conn, :src => nil
    end

    assert !Fabricate.build(:conn, :src => nil).valid?
  end

  test 'fails with no target present' do
    assert_raises(ActiveRecord::RecordInvalid) do
      Fabricate :conn, :dst => nil
    end

    assert !Fabricate.build(:conn, :dst => nil).valid?
  end
end
