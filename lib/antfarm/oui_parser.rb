require 'singleton'

module Antfarm
  class OuiParser
    include Singleton

    def self.get_name(addr)
      return Antfarm::OuiParser.instance.get_name(addr)
    end

    def initialize
      db_file = "#{Antfarm::Helpers.user_dir}/oui-db.txt"

      unless File.exists?(db_file)
        db_file = "#{Antfarm.root}/ext/oui-db.txt"
      end

      @db = Hash.new

      File.open(db_file) do |file|
        file.each do |line|
          unless line.strip.empty? or line.strip.start_with?('#')
            data = line.strip.split
            addr = data[0]
            name = data[1]

            addr.upcase!

            # TODO: document!
            next if name == 'IeeeRegi' and addr != '00:1B:C5'

            # TODO: document!
            if match = /\/(\d*)$/.match(addr)
              mask    = match[1].to_i
              bytes   = mask / 8
              offset  = (bytes * 2) + (bytes - 1)
              offset += 2 if mask % 8 == 4
              addr    = addr[0,offset]
            end

            addr.gsub!(/[-.]/, ':')

            if data.length > 2 and data[2] == '#'
              count = data.length - 3
              info  = data[3,count]
              name  =  info.join(' ')
            end

            @db[addr] = name
          end
        end
      end
    end

    def get_name(addr)
      @db.each do |k,v|
        return v if addr.strip.upcase.gsub(/[-.]/, ':').start_with?(k)
      end

      return nil
    end
  end
end
