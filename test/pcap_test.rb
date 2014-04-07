require 'test_helper'
require 'packetfu/modbus'

class PcapTest < TestCase
  test 'PCAP Parser w/ Modbus PacketFu addition and OUI parser' do
    opts = { :file => 'test/pcap-parser-test-data.pcap' }

    Antfarm.plugins['pcap'].run(opts)

    assert_equal 2, Antfarm::Models::Node.count

    src = Antfarm::Models::Node.first
    dst = Antfarm::Models::Node.last

    assert_equal 1, src.l2_ifs.count
    assert_equal 1, dst.l2_ifs.count

    assert_equal 'CA:02:03:F8:00:06', src.l2_ifs.first.eth_if.address
    assert_equal '00:0C:29:CE:53:E6', dst.l2_ifs.first.eth_if.address

    assert dst.l2_ifs.first.tags.map(&:name).include?('VMware, Inc.')

    assert src.tags.map(&:name).include?('Modbus TCP Master')
    assert dst.tags.map(&:name).include?('Modbus TCP Slave')

    conn = Antfarm::Models::Connection.first

    assert_equal src.l3_ifs.first, conn.src
    assert_equal dst.l3_ifs.first, conn.dst

    assert_equal 502, conn.dst_port
  end
end
