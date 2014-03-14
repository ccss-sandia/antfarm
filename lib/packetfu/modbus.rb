require 'packetfu'

module PacketFu
  class ModbusHeader < Struct.new(:modbus_tid, :modbus_pid, :modbus_len, :modbus_uid, :modbus_fc, :body)
    include StructFu

    def initialize(args = Hash.new)
      super(
        StructFu::Int16.new(args[:modbus_tid] || 0),
        StructFu::Int16.new(args[:modbus_pid] || 0),
        StructFu::Int16.new(args[:modbus_len] || 1),
        StructFu::Int8.new(args[:modbus_uid]  || 1),
        StructFu::Int8.new(args[:modbus_fc]   || 1),
        StructFu::String.new.read(args[:body])
      )
    end

    def to_s
      self.to_a.map { |x| x.to_s }.join
    end

    def read(str)
      force_binary(str)

      return self if str.nil?

      self[:modbus_tid].read(str[0,2])
      self[:modbus_pid].read(str[2,2])
      self[:modbus_len].read(str[4,2])
      self[:modbus_uid].read(str[6,1])
      self[:modbus_fc].read(str[7,1])
      self[:body].read(str[7,str.size]) if str.size > 7

      return self
    end

    def modbus_tid
      return self[:modbus_tid].to_i
    end

    def modbus_pid
      return self[:modbus_pid].to_i
    end

    def modbus_len
      return self[:modbus_len].to_i
    end

    def modbus_uid
      return self[:modbus_uid].to_i
    end

    def modbus_fc
      return self[:modbus_fc].to_i
    end
  end

  module ModbusHeaderMixin
    def modbus_tid
      return self.modbus_header.modbus_tid
    end

    def modbus_pid
      return self.modbus_header.modbus_pid
    end

    def modbus_len
      return self.modbus_header.modbus_len
    end

    def modbus_uid
      return self.modbus_header.modbus_uid
    end

    def modbus_fc
      return self.modbus_header.modbus_fc
    end
  end

  class ModbusPacket < Packet
    include ::PacketFu::EthHeaderMixin
    include ::PacketFu::IPHeaderMixin
    include ::PacketFu::TCPHeaderMixin
    include ::PacketFu::ModbusHeaderMixin

    attr_accessor :eth_header, :ip_header, :tcp_header, :modbus_header

    def self.can_parse?(str)
      return false unless str.size >= 61 # 54 + 7 (ETH, IP, TCP, MB ADU)
      return false unless EthPacket.can_parse?(str)
      return false unless IPPacket.can_parse?(str)
      return false unless TCPPacket.can_parse?(str)

      packet = TCPPacket.new.read(str)
      body   = packet.tcp_header.body

      if body.size > 7
        mb_pid = StructFu::Int16.new.read(body[2,2]).value
        mb_len = StructFu::Int16.new.read(body[4,2]).value

        if packet.tcp_src == 502 or packet.tcp_dst == 502
          if mb_pid.zero? and mb_len <= 250
            return true
          end
        end
      end

      return false
    end

    def read(str = nil, args = Hash.new)
      raise "Cannot parse `#{str}`" unless self.class.can_parse?(str)

      @eth_header.read(str)
      super(args)

      return self
    end

    def initialize(args = Hash.new)
      @eth_header = EthHeader.new(args).read(args[:eth])
      @ip_header  = IPHeader.new(args).read(args[:ip])

      @ip_header.ip_proto = 0x06

      @tcp_header    = TCPHeader.new(args).read(args[:tcp])
      @modbus_header = ModbusHeader.new(args).read(args[:modbus])

      @tcp_header.body = @modbus_header
      @ip_header.body  = @tcp_header
      @eth_header.body = @ip_header

      @headers = [@eth_header, @ip_header, @tcp_header, @modbus_header]

      super
    end

    def peek_format
      flags  = ' ['
      flags << self.tcp_flags_dotmap
      flags << '] '

      body = Array.new
      self.modbus_header.body.to_s.chars do |char|
        body << char.unpack('H*').first
      end

      data = ['M  ']

      data << '%-5d'  % self.to_s.size
      data << '%-21s' % "#{self.ip_saddr}:#{self.tcp_src}"
      data << '->'
      data << '%21s' % "#{self.ip_daddr}:#{self.tcp_dst}"
      data << flags
      data << 'S:'
      data << '%08x' % self.tcp_seq
      data << '|I:'
      data << '%04x' % self.ip_id
      data << '  '
      data << body.join(' ')

      return data.join
    end
  end
end
