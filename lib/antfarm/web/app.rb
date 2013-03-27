require 'csv'
require 'haml'
require 'sinatra/base'

module Antfarm
  module Web
    class Server < Sinatra::Base
      get '/' do
        haml :index
      end

      get '/new' do
        haml :new, :layout => !request.xhr?
      end

      get '/csv', :provides => 'text/csv' do
        CSV.generate do |csv|
          csv << ['name','color']

          Antfarm::Models::IpInterface.all.each do |iface|
            color = "%06x" % (rand * 0xFFFFFF)
            csv << [iface.address,color]
          end
        end
      end

      get '/json', :provides => 'text/json' do
        matrix = Array.new
        ifaces = Antfarm::Models::IpInterface.all.map(&:id)
        total  = Antfarm::Models::Connection.count

        ifaces.each do |src|
          data = Array.new

          ifaces.each do |dst|
            if src == dst
              data << 0
            else
              data << Antfarm::Models::Connection.where(:src_id => src, :dst_id => dst).count / total.to_f
            end
          end

          matrix << data
        end

        JSON.generate(matrix)
      end


      post '/upload' do
        plugin  = Antfarm.plugin('cisco-pix-asa')
        options = { file: params[:file][:tempfile].path,
          interfaces_only: true }

        plugin.run(options)
        return
      end

      get '/upload-stream', :provides => 'text/event-stream' do
        stream :keep_open do |out|
          Antfarm.outputter_callback = lambda do |msg|
            puts msg.inspect
            if not msg.is_a?(Array)
              output = "data: #{msg}\n\n"
              puts output
              out << output
            elsif msg.length == 1
              output = "data: #{msg.first}\n\n"
              puts output
              out << output
            else
              event = msg.shift
              output = "event: #{event}\ndata: #{msg.join("\n")}\n\n"
              puts output
              out << output
            end
          end
          out.callback { Antfarm.outputter_callback = nil }
        end
      end

      get '/graph' do
        haml :graph
      end

      get '/stream', :provides => 'text/event-stream' do
        stream :keep_open do |out|
          require 'json'

          nets  = Antfarm::Models::Layer3Network.all
          hosts = Array.new
          net   = nil

          nodes        = Array.new
          net_indexes  = Hash.new
          node_indexes = Hash.new

          EM::PeriodicTimer.new(0.25) do
            data = Hash.new

            if hosts.empty?
              net = nets.pop
              net_indexes[net.id] = nodes.length

              data[:node] = { :name => net.id, :group => 'LAN', :label => net.ip_network.address }
              nodes << net
              hosts = net.layer3_interfaces
            else
              node = hosts.pop.layer2_interface.node

              unless nodes.include?(node)
                node_indexes[node.id] = nodes.length
                data[:node] = { :name => node.id, :group => node.device_type, :label => node.name }
                nodes << node
              end

              data[:link] = { :source => node_indexes[node.id], :target => net_indexes[net.id], :value => 1 }
            end

            out << "data: #{JSON.generate(data)}\n\n"
          end
        end
      end
    end
  end
end
