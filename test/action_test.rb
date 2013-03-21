require 'test_helper'

class ActionTest < TestCase
  include Antfarm::Models

  test 'data persists to database' do
    action = Fabricate :action

    assert Action.count == 1
    assert Action.first.tool == 'nmap'
  end
end
