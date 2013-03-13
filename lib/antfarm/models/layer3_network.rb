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

# Layer3Network class that wraps the layer3_networks table
# in the ANTFARM database.
#
# * has many layer 3 interfaces
# * has one IP network
class Layer3Network < ActiveRecord::Base
  has_many :layer3_interfaces
  has_one  :ip_network, :foreign_key => "id", :dependent => :destroy

  before_save :clamp_certainty_factor

  validates_presence_of :certainty_factor

  # Take the given network and merge with it
  # any sub_networks of the given network.
  def self.merge(network, merge_certainty_factor = Antfarm::CF_PROVEN_TRUE)
    unless network 
      raise(ArgumentError, "nil argument supplied", caller)
    end

    for sub_network in self.networks_contained_within(network.ip_network.address)
      unless sub_network == network 
        unless merge_certainty_factor
          merge_certainty_factor = Antfarm::CF_LACK_OF_PROOF
        end

        merge_certainty_factor = Antfarm.clamp(merge_certainty_factor)

        network.layer3_interfaces << sub_network.layer3_interfaces
        network.layer3_interfaces.flatten!
        network.layer3_interfaces.uniq!

        # TODO: update network's certainty factor using sub_network's certainty factor.
        
        network.save false

        # Because of :dependent => :destroy above, calling destroy
        # here will also cause destroy to be called on ip_network
        sub_network.destroy
      end
    end
  end

  # Find the Layer3Network with the given address.
  def self.network_addressed(ip_net_str)
    # Calling network_containing here because if a network already exists that encompasses
    # the given network, we want to automatically use that network instead.
    # TODO: figure out how to use alias with class methods
    self.network_containing(ip_net_str)
  end

  # Find the network the given network is a sub_network of, if one exists.
  def self.network_containing(ip_net_str)
    unless ip_net_str
      raise(ArgumentError, "nil argument supplied", caller)
    end

    # Don't want to require a Layer3Network to be passed in case a check is being performed
    # before a Layer3Network is created.
    network = Antfarm::IPAddrExt.new(ip_net_str)

    ip_nets = IpNetwork.find(:all)
    for ip_net in ip_nets
      if Antfarm::IPAddrExt.new(ip_net.address).network_in_network?(network)
        return Layer3Network.find(ip_net.id)
      end
    end

    return nil
  end

  # Find any Layer3Networks that are sub_networks of the given network.
  def self.networks_contained_within(ip_net_str)
    unless ip_net_str
      raise(ArgumentError, "nil argument supplied", caller)
    end

    # Don't want to require a Layer3Network to be passed in case a check is being performed
    # before a Layer3Network is created.
    network = Antfarm::IPAddrExt.new(ip_net_str)
    sub_networks = Array.new

    ip_nets = IpNetwork.find(:all)
    for ip_net in ip_nets
      sub_networks << Layer3Network.find(ip_net.id) if network.network_in_network?(ip_net.address)
    end

    return sub_networks
  end

  # This is for ActiveScaffold
  def to_label #:nodoc:
    return "#{id} -- #{ip_network.address}" if ip_network
    return "#{id} -- Generic Layer3 Network"
  end

  #######
  private
  #######

  def clamp_certainty_factor
    self.certainty_factor = Antfarm.clamp(self.certainty_factor)
  end
end

