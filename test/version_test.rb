require 'helper'

class VersionTest < TestCase
  test 'correct version' do
    assert '1.0.0', Antfarm.version
  end
end
