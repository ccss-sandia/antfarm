# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
# Derived From: code written by Michael Berg <mjberg@sandia.gov>
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 

# IpNetwork class that wraps the ip_networks table
# in the ANTFARM database.
#
# * belongs to a layer 3 network
# * belongs to a private network
class IpNetwork < ActiveRecord::Base
  belongs_to :layer3_network, :foreign_key => "id"
  belongs_to :private_network

  before_create :create_layer3_network
  before_create :set_private_address
  after_create  :merge_layer3_networks

  # Protocol of the layer 3 network automatically
  # created for this IP network.
  attr_writer :layer3_network_protocol

  # Description of the private network to be
  # created for this IP network if it's private.
  attr_writer :private_network_description

  validates_presence_of :address

  # Overriding the address setter in order to create an instance variable for an
  # Antfarm::IPAddrExt object ip_net.  This way the rest of the methods in this
  # class can confidently access the ip address for this network.
  #
  # the method address= is called by the constructor of this class.
  def address=(ip_addr) #:nodoc:
    @ip_net = Antfarm::IPAddrExt.new(ip_addr)
    super(@ip_net.to_cidr_string)
  end

  # Validate data for requirements before saving network to the database.
  #
  # Was using validate_on_create, but decided that these restraints should occur
  # on anything saved to the database at any time, including a create and an update.
  def validate #:nodoc:
    # Don't save the network if it's a loopback network.
    unless !@ip_net.loopback_address?
      errors.add(:address, "loopback address not allowed")
    end
  end

  # This is for ActiveScaffold
  def to_label #:nodoc:
    return address
  end

  #######
  private
  #######

  def set_private_address
    self.private = @ip_net.private_address?
    # TODO: Create private network objects.
    return # if we don't do this, then a false is returned and the save fails
  end

  def create_layer3_network
    # If we get to this point, then we know a network does not
    # already exist because validate gets called before
    # this method and we're checking for existing networks in
    # validate.  Therefore, we know a new network needs to be created,
    # unless it was specified by the user.
    unless self.layer3_network
      layer3_network = Layer3Network.new :certainty_factor => 0.75
      layer3_network.protocol = @layer3_network_protocol if @layer3_network_protocol
      if layer3_network.save
        logger.info("IpNetwork: Created Layer 3 Network")
      else
        logger.warn("IpNetwork: Errors occured while creating Layer 3 Network")
        layer3_network.errors.each_full do |msg|
          logger.warn(msg)
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
end

