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
    class Node < ActiveRecord::Base
      has_many :layer2_interfaces, :inverse_of => :node,           :dependent => :destroy
      has_many :layer3_interfaces, :through => :layer2_interfaces, :dependent => :destroy
      has_many :services
      has_one  :operating_system

      accepts_nested_attributes_for :layer2_interfaces

      validates :certainty_factor, :presence => true

      before_save :clamp_certainty_factor

      # Find and return nodes found with the given name.
      def self.node_named(name)
        unless name
          raise AntfarmError, 'nil argument supplied', caller
        end

        nodes = self.find_all_by_name(name)

        if nodes.empty?
          Antfarm.log :warn, 'Node: did not find an existing node with given name.'
          return nil
        else
          Antfarm.log :info, 'Node: found existing nodes with given name.'
          return nodes
        end
      end

      # Find and return all the nodes found that are the given type.
      def self.nodes_of_device_type(device_type)
        unless device_type
          raise AntfarmError, 'nil argument supplied', caller
        end

        nodes = self.find_all_by_device_type(device_type)

        if nodes.empty?
          Antfarm.log :warn, 'Node: did not find any existing nodes of given device type.'
          return nil
        else
          Antfarm.log :info, 'Node: found existing nodes of given device type.'
          return nodes
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
