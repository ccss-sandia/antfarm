require 'test_helper'

class CiscoIOSTest < TestCase
  test 'Cisco IOS config parsing' do

    class Antfarm::Plugin
      def read_data(path, &block)
        data = StringIO.new

        data << "version 12.2\n"
        data << "hostname InetRouter\n"
        data << "network-object 192.168.0.0 255.255.255.0\n"
        data << "network-object host 192.168.0.101\n"
        data << "interface FastEthernet0/0\n"
        data << " ip address 10.0.1.1 255.255.255.0\n"
        data << " duplex full\n"
        data << " speed auto\n"
        data << "interface FastEthernet0/1\n"
        data << " ip address 10.0.2.254 255.255.255.0\n"
        data << " duplex full\n"
        data << " speed auto\n"
        data << "ip route 10.0.3.0 255.255.255.0 10.0.2.1\n"

        data.rewind

        yield path, data
      end
    end

    opts = { :file => '/foo/bar/sucka' }
    Antfarm.plugins['cisco-ios'].run(opts)

    # one for device, one for network-object host, one for route
    assert_equal 3, Antfarm::Models::Node.count

    # first node created should be the actual Cisco device
    device = Antfarm::Models::Node.first
    assert_equal 'InetRouter', device.name
    assert device.tags.map(&:name).include?('router')

    device_ips = device.l3_ifs.map { |iface| iface.ip_if.address }
    assert device_ips.include?('10.0.1.1')
    assert device_ips.include?('10.0.2.254')

    assert_equal 4, Antfarm::Models::L3Net.count

    assert Antfarm::Models::L3Net.network_addressed('10.0.1.0/24')
    assert Antfarm::Models::L3Net.network_addressed('10.0.2.0/24')
    assert Antfarm::Models::L3Net.network_addressed('10.0.3.0/24')
    assert Antfarm::Models::L3Net.network_addressed('192.168.0.0/24')

    router = Antfarm::Models::L3If.interface_addressed('10.0.2.1')
    assert router.l2_if.node.tags.map(&:name).include?('router')
  end
end
