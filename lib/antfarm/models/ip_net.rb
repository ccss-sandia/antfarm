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

module Antfarm
  module Models
    class IPNet < ActiveRecord::Base
      attr_accessor :addr # IPAddrExt object (as opposed to just address string)

      belongs_to :l3_net,      :inverse_of => :ip_net
      belongs_to :private_net, :inverse_of => :ip_nets

      before_validation :create_l3_net, :on => :create

      before_create :set_private_address
      after_create  :merge_l3_nets

      validates :address, :presence => true
      validates :l3_net,  :presence => true

      # Create the `@addr` instance variable on the record when model is found
      after_find do |record|
        @addr = Antfarm::IPAddrExt.new(record.address)
      end

      # Validate data for requirements before saving network to the database.
      #
      # Was using validate_on_create, but decided that these restraints should
      # occur on anything saved to the database at any time, including a create
      # and an update.
      validates_each :address do |record, attr, value|
        begin
          record.addr = Antfarm::IPAddrExt.new(value)

          # Don't save the network if it's a loopback network.
          if record.addr.loopback_address?
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
        self.private = @addr.private_address?

        if self.private
          self.create_private_net :description => "Private network for #{self.address}"
        end
      end

      def create_l3_net
        unless self.l3_net
          layer3_network = L3Net.new :certainty_factor => 0.75
          if layer3_network.save
            Antfarm.log :info, 'IPNet: Created Layer 3 Network'
          else
            Antfarm.log :warn, 'IPNet: Errors occured while creating Layer 3 Network'
            layer3_network.errors.full_messages do |msg|
              Antfarm.log :warn, msg
            end
          end

          self.l3_net = layer3_network
        end
      end

      def merge_l3_nets
        # Merge any existing networks already in the database that are
        # sub_networks of this new network.
        L3Net.merge(self.l3_net, 0.80)
      end
    end
  end
end
