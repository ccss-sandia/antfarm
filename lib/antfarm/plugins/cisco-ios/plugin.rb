################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
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
  module CiscoIOS
    def self.registered(plugin)
      plugin.name = 'cisco-ios'
      plugin.info = {
        :desc   => 'Configuration parser for Cisco IOS',
        :author => 'Bryan T. Richardson'
      }
      plugin.options = [{
        :name     => 'file',
        :desc     => 'Config file to parse (can also be a directory of files)',
        :type     => String,
        :required => true
      },
      {
        :name => 'interfaces_only',
        :desc => 'Only parse interfaces (ignore defined network objects and hosts)'
      }]
    end

    def run(opts = Hash.new)
      check_options(opts)

      files = Array.new

      if File.directory?(opts[:file])
        Dir["#{opts[:file]}/*"].each do |file|
          files << File.expand_path(file, opts[:file])
        end
      elsif File.exists?(opts[:file])
        files << opts[:file]
      else
        raise "Config file #{opts[:file]} doesn't exist"
      end

      files.each do |file|
        Antfarm.output "Parsing config file #{file}"

        ios_version_regexp  = /^(\A.*|IOS|PIX|ASA)[V|v]ersion ((\d+)\.(\d+)(\((\d+)\))?)/
        hostname_regexp     = /^hostname (\S+)/
        ipv4_regexp         = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
        iface_addr_regexp   = /ip address #{ipv4_regexp} #{ipv4_regexp}/ 
        net_object_regexp   = /network-object #{ipv4_regexp} #{ipv4_regexp}/
        net_obj_host_regexp = /network-object host #{ipv4_regexp}/
        route_regexp        = /^route \S+ #{ipv4_regexp} #{ipv4_regexp} #{ipv4_regexp}/

        ios_version = nil
        hostname    = nil

        interfaces = Array.new
        addresses  = Array.new
        networks   = Array.new

        File.open(file) do |list|
          list.each do |line|
            if match = ios_version_regexp.match(line)
              ios_version = match[2].to_i unless ios_version
            elsif match = hostname_regexp.match(line)
              hostname = match[1] unless hostname
            elsif match = iface_addr_regexp.match(line)
              interfaces << "#{match[1]}/#{match[2]}"
            elsif !opts[:interfaces_only] and match = net_object_regexp.match(line)
              networks << "#{match[1]}/#{match[2]}"
            elsif !opts[:interfaces_only] and match = net_obj_host_regexp.match(line)
              addresses << match[1]
            elsif !opts[:interfaces_only] and match = route_regexp.match(line)
              networks  << "#{match[1]}/#{match[2]}" unless match[1] == '0.0.0.0'
              addresses << match[3]
            end
          end
        end

        if ios_version.nil?
          Antfarm.output 'Unrecognized IOS version.'
        else
          Antfarm.output "  IOS major version: #{ios_version}"

          if hostname.nil?
            hostname = File.basename(file, '.*')

            Antfarm.output '  Hostname not specified in config file.'
            Antfarm.output '  Using file name as hostname.'
          end

          Antfarm.output "  Hostname: #{hostname}"

          interfaces.uniq!

          node = Antfarm::Models::Node.find_or_create_by_name!(
            :name => hostname, :device_type => 'Cisco PIX/ASA',
            :certainty_factor => 1.0
          )

          interfaces.each do |address|
            Antfarm.output "  Creating IP interface for #{address} based on interface configuration."

            iface = Antfarm::Models::Layer3Interface.interface_addressed(address)

            if iface
              Antfarm.output "  Found an existing interface with address #{address}."
              Antfarm.output '  Updating its associated node.'

              node.merge_from(iface.layer2_interface.node)
            else
              node.layer2_interfaces.create(
                :certainty_factor => 1.0, :media_type => 'Ethernet',
                :layer3_interfaces_attributes => [{ :certainty_factor => 1.0, :protocol => 'IP',
                  :ip_interface_attributes => { :address => address }
                }]
              )
            end
          end

          unless opts[:interfaces_only]
            addresses.uniq!
            networks.uniq!

            addresses.each do |address|
              Antfarm.output "  Creating IP interface for #{address} based on host or route entry."

              iface = Antfarm::Models::Layer3Interface.interface_addressed(address)

              if iface
                Antfarm.output "  Record already exists for #{address}."
              else
                Antfarm::Models::Node.create!(
                  :certainty_factor => 0.25, :device_type => 'generic host',
                  :layer2_interfaces_attributes => [{ :certainty_factor => 1.0, :media_type => 'Ethernet',
                    :layer3_interfaces_attributes => [{ :certainty_factor => 1.0, :protocol => 'IP',
                      :ip_interface_attributes => { :address => address }
                    }]
                  }]
                )
              end
            end

            networks.each do |network|
              Antfarm.output "  Creating IP network for #{network} based on network object entry."

              l3net = Antfarm::Models::Layer3Network.network_addressed(network)

              if l3net
                Antfarm.output "  Record already exists for #{network}."
              else
                Antfarm::Models::Layer3Network.create!(
                  :certainty_factor => 1.0,
                  :ip_net_attributes => { :address => network }
                )
              end
            end
          end
        end
      end
    end
  end
end

Antfarm.register(Antfarm::CiscoIOS)
