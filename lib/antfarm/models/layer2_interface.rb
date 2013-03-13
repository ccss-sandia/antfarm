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

# Layer2Interface class that wraps the layer2_interfaces table
# in the ANTFARM database.
#
# * has many layer 3 interfaces
# * has one ethernet interface
# * belongs to a node
#
# What to test:
#   * certainty factor is provided and clamped properly
#   * interface_addressed works correctly
#   * creates a generic node or a specific node if info provided
#   * associates itself with an existing node if one is found to exist
#   * creates an ethernet interface if info provided
#   * creation of interface fails if creation of ethernet_interface or
#     node fails

module Antfarm
  module Models
    class Layer2Interface < ActiveRecord::Base
      has_many   :layer3_interfaces
      has_one    :ethernet_interface, :inverse_of => :layer2_interface, :foreign_key => 'id'
      belongs_to :node

      accepts_nested_attributes_for :ethernet_interface
#     accepts_nested_attributes_for :layer3_interfaces

      before_save :clamp_certainty_factor

      validates :node,             :presence => true
      validates :certainty_factor, :presence => true

      # Find and return the layer 2 interface
      # with the given ethernet address.
      def self.interface_addressed(mac_addr_str)
        unless mac_addr_str
          raise ArgumentError, 'nil argument supplied', caller
        end

        if eth_if = EthernetInterface.find_by_address(mac_addr_str)
          return eth_if.layer2_interface
        else
          return nil
        end
      end

      #######
      private
      #######

      def clamp_certainty_factor
        self.certainty_factor = Antfarm.clamp(self.certainty_factor)
      end
    end
  end
end
