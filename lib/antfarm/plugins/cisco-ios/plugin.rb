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

      read_data(opts[:file]) do |path,lines|
        Antfarm.output "Parsing config file #{path}"

        ios_version_regexp  = /.*[V|v]ersion ((\d+)\.(\d+)(\((\d+)\))?)/
        hostname_regexp     = /^hostname (\S+)/
        ipv4_regexp         = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
        iface_addr_regexp   = /ip address #{ipv4_regexp} #{ipv4_regexp}/
        net_object_regexp   = /network-object #{ipv4_regexp} #{ipv4_regexp}/
        net_obj_host_regexp = /network-object host #{ipv4_regexp}/
        route_regexp        = /.*route.* #{ipv4_regexp} #{ipv4_regexp} #{ipv4_regexp}/

        ios_version = nil
        hostname    = nil

        interfaces = Array.new
        addresses  = Array.new
        networks   = Array.new

        lines.each do |line|
          if match = ios_version_regexp.match(line)
            ios_version = match[2].to_i unless ios_version
          elsif match = hostname_regexp.match(line)
            hostname = match[1] unless hostname
          elsif match = iface_addr_regexp.match(line)
            interfaces << "#{match[1]}/#{match[2]}"
          elsif !opts[:interfaces_only] and match = net_object_regexp.match(line)
            networks << "#{match[1]}/#{match[2]}"
          elsif !opts[:interfaces_only] and match = net_obj_host_regexp.match(line)
            addresses << ['host', match[1]]
          elsif !opts[:interfaces_only] and match = route_regexp.match(line)
            networks  << "#{match[1]}/#{match[2]}" unless match[1] == '0.0.0.0'
            addresses << ['router', match[3]]
          end
        end

        if ios_version.nil?
          Antfarm.output 'Unrecognized IOS version.'
        else
          Antfarm.output "  IOS major version: #{ios_version}"

          if hostname.nil?
            hostname = File.basename(path, '.*')

            Antfarm.output '  Hostname not specified in config file.'
            Antfarm.output '  Using file name as hostname.'
          end

          Antfarm.output "  Hostname: #{hostname}"

          interfaces.uniq!

          node = Antfarm::Models::Node.find_or_create_by_name!(
            :name => hostname, :certainty_factor => Antfarm::CF_PROVEN_TRUE,
            :tags => [
              Antfarm::Models::Tag.new(:name => 'router'),
              Antfarm::Models::Tag.new(:name => 'Cisco'),
              Antfarm::Models::Tag.new(:name => 'PIX'),
              Antfarm::Models::Tag.new(:name => 'ASA')
            ]
          )

          interfaces.each do |address|
            Antfarm.output "  Creating IP interface for #{address} based on interface configuration."

            iface = Antfarm::Models::L3If.interface_addressed(address)

            if iface
              Antfarm.output "  Found an existing interface with address #{address}."
              Antfarm.output '  Updating its associated node.'

              node.merge_from(iface.l2_if.node)
            else
              node.l2_ifs.create(
                :certainty_factor => Antfarm::CF_LIKELY_TRUE,
                :l3_ifs_attributes => [{ :certainty_factor => Antfarm::CF_PROVEN_TRUE,
                  :protocol => 'IP', :ip_if_attributes => { :address => address }
                }]
              )
            end
          end

          unless opts[:interfaces_only]
            addresses.uniq!
            networks.uniq!

            addresses.each do |address|
              Antfarm.output "  Creating IP interface for #{address[1]} based on #{address[0]} entry."

              iface = Antfarm::Models::L3If.interface_addressed(address[1])

              if iface
                Antfarm.output "  Record already exists for #{address[1]}."
                node = iface.l2_if.node
                unless node.tags.include?(address[0])
                  node.tags << Antfarm::Models::Tag.new(:name => address[0])
                end
              else
                Antfarm::Models::Node.create!(
                  :certainty_factor => Antfarm::CF_LACK_OF_PROOF,
                  :l2_ifs_attributes => [{ :certainty_factor => Antfarm::CF_PROVEN_TRUE,
                    :l3_ifs_attributes => [{
                      :certainty_factor => Antfarm::CF_PROVEN_TRUE, :protocol => 'IP',
                      :ip_if_attributes => { :address => address[1] }
                    }]
                  }], :tags => [Antfarm::Models::Tag.new(:name => address[0])]
                )
              end
            end

            networks.each do |network|
              Antfarm.output "  Creating IP network for #{network} based on network object entry."

              l3net = Antfarm::Models::L3Net.network_addressed(network)

              if l3net
                Antfarm.output "  Record already exists for #{network}."
              else
                Antfarm::Models::L3Net.create!(
                  :certainty_factor => Antfarm::CF_PROVEN_TRUE,
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
