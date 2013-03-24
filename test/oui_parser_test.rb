require 'test_helper'

class OuiParserTest < TestCase
  test 'parser returns correct vendor name' do
    assert Antfarm::OuiParser.get_name('00:01:E3:12:34:56') == 'Siemens AG'
    assert Antfarm::OuiParser.get_name('W0:01:E3:12:34:56').nil?
  end
end
