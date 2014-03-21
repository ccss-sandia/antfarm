################################################################################
#                                                                              #
# Copyright (2008-2014) Sandia Corporation. Under the terms of Contract        #
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

require 'ipaddress'

module Antfarm
  class IPAddrExt < IPAddress::IPv4
    def initialize(value)
      throw ArgumentError, 'Must provide an address' if value.nil?
      super(value)
    end

    def net_cidr_string
      return "#{self.network}/#{self.prefix}"
    end

    def to_cidr_string
      return "#{self.address}/#{self.prefix}"
    end

    # TODO: track down the IPv6 private use ranges and include them
    def private_address?
      return self.private?
    end

    #TODO: track down IPv6 localnet mask (guessing /10 for now)
    def loopback_address?
      loopback = Antfarm::IPAddrExt.new('127.0.0.0/8')
      return loopback.include?(self)
    end

    # Decides if the given network is a subset of this network.
    # This method was added since SQLite3 cannot handle CIDR's
    # 'natively' like PostgreSQL can. Note that this method
    # also works if the network given is actually a host.
    def network_in_network?(network)
      if network.kind_of?(String)
        network = Antfarm::IPAddrExt.new(network)
      elsif not network.kind_of?(Antfarm::IPAddrExt)
        raise(ArgumentError, "argument should be either a String or an Antfarm::IPAddrExt object", caller)
      end

      return self.include?(network)
    end
  end
end
