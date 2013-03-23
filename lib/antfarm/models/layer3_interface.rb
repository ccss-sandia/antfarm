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
    class Layer3Interface < ActiveRecord::Base
      has_many :tags, :as => :taggable
      has_many :inbound_connections,  :class_name => 'Connection', :foreign_key => 'target_layer3_interface_id'
      has_many :outbound_connections, :class_name => 'Connection', :foreign_key => 'source_layer3_interface_id'

      has_one :ip_interface, :inverse_of => :layer3_interface, :dependent => :destroy

      belongs_to :layer2_interface, :inverse_of => :layer3_interfaces
      belongs_to :layer3_network,   :inverse_of => :layer3_interfaces

      accepts_nested_attributes_for :ip_interface

      validates :layer2_interface, :presence => true
      validates :certainty_factor, :presence => true

      before_save :clamp_certainty_factor

      # Find and return the layer 3 interface
      # with the given IP address.
      def self.interface_addressed(ip_addr_str)
        unless ip_addr_str
          raise AntfarmError, 'nil argument supplied', caller
        end

        if ip_if = IpInterface.find_by_address(ip_addr_str)
          return ip_if.layer3_interface
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
