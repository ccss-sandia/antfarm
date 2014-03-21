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
    # Data model for an IP Interface
    #
    # When IP Interfaces are saved (create/update), the <tt>address</tt>
    # attribute is validated and checks are run to see if a L3 Network exists
    # to associate the interface to. If one does not already exist, a new L3
    # Network model is created and assocated with the IP Interface. The rules
    # for determining what size of new L3 Network to create are described as
    # follows:
    #
    # If subnet information is included in the IP address provided, then that
    # is used to create the new L3 Network.
    #
    # Otherwise, a default subnet prefix (usually /30) is used to create the
    # new L3 Network. If, when the new L3 Network is created, it results in the
    # address being a network address rather than a host address (for example,
    # 192.168.0.100/30), the prefix is changed to /29. One can override the
    # default subnet prefix to use when creating new L3 Networks by wrapping
    # the creation code with the <tt>IPIf.execute_with_prefix</tt> call.
    #
    #    Antfarm::Models::IPIf.execute_with_prefix(24) do
    #      Antfarm::Models::IPIf.new(:address => '192.168.0.100')
    #    end
    class IPIf < ActiveRecord::Base
      # Representation of IP address as <tt>Antfarm::IPAddrExt</tt> object
      #--
      # This is useful for tracking the subnet prefix (if provided) during
      # initial creation of the IP Interface model, which is used for deciding
      # what type of L3 Network to create.
      #++
      attr_accessor :addr # IPAddrExt object so we can track prefix if provided

      belongs_to :l3_if, :inverse_of => :ip_if

      # TODO: figure out why it fails when `after_save` is used...
      #
      # Recursion seems to occur in the `associate_l3_net` method when called
      # after every save... it's like the call to update attributes on the L3
      # Interface for this IP Interface causes this model to be saved again,
      # therein causing recursion since the `associate_l3_net` method is called
      # once again.
      after_create :create_ip_net
      after_create :associate_l3_net

      validates :address, :presence => true
      validates :l3_if,   :presence => true

      # Create the `@addr` instance variable on the record when model is found
      after_find do |record|
        @addr = Antfarm::IPAddrExt.new(record.address)
      end

      # Validate data for requirements before saving interface to the database.
      #
      # Was using validate_on_create, but decided that restraints should occur
      # on anything saved to the database at any time, including a create and an
      # update.
      validates_each :address do |record, attr, value|
        begin
          # This block is run outside of the context of a model instance,
          # so `@addr` cannot be used here. Rather, we must reference it via
          # the attribute accessor `addr` available on the model instance.
          record.addr    = Antfarm::IPAddrExt.new(value)
          record.address = record.addr.to_s

          # Don't save the interface if it's a loopback address.
          if record.addr.loopback_address?
            record.errors.add(:address, 'loopback address not allowed')
          end

          # If the address is public and it already exists in the database,
          # don't create a new one but still create a new IP Network just in
          # case the data given for this address includes more detailed
          # information about its network.
          unless record.addr.private_address?
            if interface = IPIf.find_by_address(record.address)
              interface.update_attribute :address, value
              message = "#{record.address} already exists, but a new IP Network was created"
              record.errors.add(:address, message)
              Antfarm.log :info, message
            end
          end
        rescue ArgumentError
          record.errors.add(:address, "Invalid IP address: #{value}")
        end
      end

      # Allow prefix provided to be nil just in case this call is part of a loop
      # that may or may not need to change the prefix.
      def self.execute_with_prefix(prefix = nil, &block)
        if prefix.nil?
          yield
        else
          original_prefix = Antfarm.config.prefix
          Antfarm.config.prefix = prefix.to_i
          yield
          Antfarm.config.prefix = original_prefix
        end
      end

      #######
      private
      #######

      # Create an IP Network (and its associated L3 Network) that would contain
      # the IP address provided for this IP Interface model unless one already
      # exists.
      def create_ip_net
        # Check to see if a network exists that contains this address.
        # If not, create a small one that does.
        unless L3Net.network_containing(@addr.to_cidr_string)
          if @addr.prefix == 32 # no subnet data provided
            @addr.prefix = Antfarm.config.prefix # defaults to /30

            # address for this interface shouldn't be a network address...
            if @addr == @addr.network
              @addr.prefix = Antfarm.config.prefix - 1
            end

            certainty_factor = Antfarm::CF_LIKELY_FALSE
          else
            certainty_factor = Antfarm::CF_PROVEN_TRUE
          end

          L3Net.create!(
            :certainty_factor => certainty_factor,
            :protocol => 'IP',
            :ip_net_attributes => { :address => @addr.net_cidr_string }
          )
        end
      end

      # Based on the current value of the <tt>address</tt> attribute, checks to
      # see if an existing L3 Network would contain the IP address. If so, this
      # model is associated with the L3 Network.
      def associate_l3_net
        if layer3_network = L3Net.network_containing(self.address)
          self.l3_if.update_attribute :l3_net, layer3_network
        end
      end
    end
  end
end
