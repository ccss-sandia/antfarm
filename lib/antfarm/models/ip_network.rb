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
    class IpNetwork < ActiveRecord::Base
      belongs_to :layer3_network,  :inverse_of => :ip_network
      belongs_to :private_network, :inverse_of => :ip_networks

      before_validation :create_layer3_network, :on => :create

      before_create :set_private_address
      after_create  :merge_layer3_networks
      after_create  :publish_info

      validates :address,        :presence => true
      validates :layer3_network, :presence => true

      # Overriding the address setter in order to create an instance variable for an
      # Antfarm::IPAddrExt object ip_net.  This way the rest of the methods in this
      # class can confidently access the ip address for this network.
      #
      # the method address= is called by the constructor of this class.
#     def address=(ip_addr) #:nodoc:
#       @ip_net = Antfarm::IPAddrExt.new(ip_addr)
#       super(@ip_net.to_cidr_string)
#     end

      # Validate data for requirements before saving network to the database.
      #
      # Was using validate_on_create, but decided that these restraints should occur
      # on anything saved to the database at any time, including a create and an update.
      validates_each :address do |record, attr, value|
        begin
          addr = Antfarm::IPAddrExt.new(value)

          # Don't save the network if it's a loopback network.
          if addr.loopback_address?
            record.errors.add(:address, "loopback address not allowed")
          end
        rescue ArgumentError
          record.errors.add(:address, "Invalid IP network: #{value}")
        end
      end

      #######
      private
      #######

      def set_private_address
        self.private = Antfarm::IPAddrExt.new(self.address).private_address?

        if self.private
          self.create_private_network :description => "Private network for #{self.address}"
        end
      end

      def create_layer3_network
        unless self.layer3_network
          layer3_network = Layer3Network.new :certainty_factor => 0.75
          if layer3_network.save
            Antfarm.log :info, 'IpNetwork: Created Layer 3 Network'
          else
            Antfarm.log :warn, 'IpNetwork: Errors occured while creating Layer 3 Network'
            layer3_network.errors.full_messages do |msg|
              Antfarm.log :warn, msg
            end
          end

          self.layer3_network = layer3_network
        end
      end

      def merge_layer3_networks
        # Merge any existing networks already in the database that are
        # sub_networks of this new network.
        Layer3Network.merge(self.layer3_network, 0.80)
      end

      def publish_info
        data = { :node => { :name => "net:#{self.id}", :group => 'LAN', :label => self.address } }
        Antfarm.output 'create', JSON.generate(data)
      end
    end
  end
end
