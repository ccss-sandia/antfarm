require 'test_helper'
require 'packetfu/modbus'

class PcapParserTest < TestCase
  test 'modbus parser works and so does oui parser' do
    PacketFu::PcapFile.read_packets('pcap-parser-test-data.pcap') do |pkt|
      begin
        assert pkt.proto.include?('IP')
        assert pkt.proto.include?('TCP')
        assert pkt.proto.include?('Modbus')

        srcvendor = Antfarm::OuiParser.get_name(pkt.eth_saddr)
        dstvendor = Antfarm::OuiParser.get_name(pkt.eth_daddr)

        assert       srcvendor.nil?
        assert_equal 'VMware, Inc.', dstvendor
      rescue
        assert false
      end
    end
  end
end
