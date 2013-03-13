################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

require 'ipaddr'

module Antfarm
  # Some explanation to having @netmask and such:
  #   If you create a new IPAddr object and you include
  #   the network information for the IP address, IPAddr
  #   doesn't keep track of the actual address, and
  #   instead just keeps track of the network.  For
  #   example, if you were to create a new IPAddr object
  #   using the following code:
  #
  #   IPAddr.new("192.168.101.5/24")
  #
  #   the resulting object would be of the form:
  #
  #   <IPAddr: IPv4:192.168.101.0/255.255.255.0>
  #
  #   and there would be no way to retrieve the original
  #   address (192.168.101.5).  By creating this class,
  #   Michael has made it possible to keep track of both
  #   the address and the network information.  This is
  #   useful in the case of creating a new IPInterface
  #   object.
  #
  # TODO: If a netmask is given, should we somehow check
  #       to see if an address is being given with network
  #       information or if a network is being specified,
  #       and if it is a network, should we validate that
  #       the network address is valid with the given
  #       netmask?  This may be done automatically... I
  #       need to look more into how IPAddr works.
  #
  # TODO: use IpAddress gem instead...

  class IPAddrExt < IPAddr
    def initialize(value)
      throw ArgumentError, 'Must provide an address' if value.nil?

      address,netmask = value.split('/')
      super(address)

      if self.ipv4?
        @netmask = IPAddr.new('255.255.255.255')
        @addr_bits = 32
      elsif self.ipv6?
        @netmask = IPAddr.new('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff')
        @addr_bits = 128
      else
        #TODO: Error
      end
   
      if netmask
        @netmask = @netmask.mask(netmask)
      end
    end

    attr_accessor :netmask

    def netmask_length
      mask_len = @addr_bits
      unless (~@netmask).to_i == 0
        res = Math.log((~@netmask).to_i) / Math.log(2)
        if res.finite?
          mask_len -= res.round
        end
      end

      return mask_len
    end

    def network
      return self.mask(self.netmask.to_s)
    end

    def to_cidr_string
      str = sprintf("%s/%s", self.network.to_string, self.netmask_length.to_s)
      return str
    end

    def broadcast
      return self.network | ~self.netmask
    end
   
    # TODO: track down the IPv6 private use ranges and include them
    def private_address?
      private_addr_list = [
        '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16',
        'fe80::/10', 'fec0::/10'
      ]
      return self.in_address_list?(private_addr_list)
    end

    #TODO: track down IPv6 localnet mask (guessing /10 for now)
    def loopback_address?
      loopback_addr_list = ['127.0.0.0/8', '::1', 'fe00::/10']
      return self.in_address_list?(loopback_addr_list)
    end

    # Need to verify the IPv4 multicast addrs (couldn't find the whole
    # block, only the currently assigned ranges within the block)
    def multicast_address?
      multicast_addr_list = ['224.0.0.0/4', 'ff00::/8']
      return self.in_address_list?(multicast_addr_list)
    end

    def in_address_list?(addr_str_list)
      for addr_str in addr_str_list
        addr = IPAddr.new(addr_str)
        if addr.include?(self)
          return true
        end
      end

      return false    
    end

    # Decides if the given network is a subset of this network.
    # This method was added since SQLite3 cannot handle CIDR's
    # 'natively' like PostgreSQL can. Note that this method
    # also works if the network given is actually a host.
    def network_in_network?(network)
      broadcast = nil

      if network.kind_of?(String)
        broadcast = IPAddrExt.new(network).broadcast
        network = IPAddr.new(network)
      elsif network.kind_of?(Antfarm::IPAddrExt)
        broadcast = network.broadcast
        network = IPAddr.new(network.to_cidr_string)
      else
        raise(ArgumentError, "argument should be either a String or an Antfarm::IPAddrExt object", caller)
      end

      return false unless IPAddr.new(self.to_cidr_string).include?(network)
      return false unless IPAddr.new(self.to_cidr_string).include?(broadcast)
      return true
    end
  end
end
