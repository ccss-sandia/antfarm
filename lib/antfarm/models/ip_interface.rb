################################################################################
#                                                                              #
# Copyright (2008-2012) Sandia Corporation. Under the terms of Contract        #
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

module Antfarm
  module Models
    class IpInterface < ActiveRecord::Base
      belongs_to :layer3_interface, :inverse_of => :ip_interface

      validates :address,          :presence => true
      validates :layer3_interface, :presence => true

      # Overriding the address setter in order to create an instance variable for an
      # Antfarm::IPAddrExt object ip_addr. This way the rest of the methods in this
      # class can confidently access the ip address for this interface. IPAddr also
      # validates the address.
      #
      # the method address= is called by the constructor of this class.
#     def address=(ip_addr) #:nodoc:
#       @ip_addr = Antfarm::IPAddrExt.new(ip_addr)
#       super(@ip_addr.to_s)
#     end

      # Validate data for requirements before saving interface to the database.
      #
      # Was using validate_on_create, but decided that restraints should occur
      # on anything saved to the database at any time, including a create and an update.
      validates_each :address do |record, attr, value|
        begin
          addr = Antfarm::IPAddrExt.new(value)

          # Don't save the interface if it's a loopback address.
          if addr.loopback_address?
            errors.add(:address, 'loopback address not allowed')
          end

          # If the address is public and it already exists in the database, don't create
          # a new one but still create a new IP Network just in case the data given for
          # this address includes more detailed information about its network.
          unless addr.private_address?
            interface = IpInterface.find_by_address(value)
            if interface
              create_ip_network
              record.errors.add(:address, "#{value} already exists, but a new IP Network was created")
            end
          end
        rescue ArgumentError
          record.errors.add(:address, "Invalid IP address: #{value}")
        end
      end

      #######
      private
      #######

      # TODO: move this to layer3_network?
      def create_ip_network
        # Check to see if a network exists that contains this address.
        # If not, create a small one that does.
        layer3_network = Layer3Network.network_containing(@ip_addr.to_cidr_string)
        unless layer3_network
          network = @ip_addr.clone
          if network == network.network
            network.netmask = network.netmask << 3
          end
          ip_network = IpNetwork.new :address => network.to_cidr_string
          ip_network.layer3_network_protocol = @layer3_network_protocol if @layer3_network_protocol
          if ip_network.save
            logger.info('IpInterface: Created IP Network')
          else
            logger.warn('IpInterface: Errors occured while creating IP Network')
            ip_network.errors.each_full do |msg|
              logger.warn(msg)
            end
          end
          layer3_network = ip_network.layer3_network
        end
        return layer3_network
      end
    end
  end
end
