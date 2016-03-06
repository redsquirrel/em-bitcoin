require 'eventmachine'
require 'bitcoin'
require 'resolv'

module EventMachine::Bitcoin
  module ConnectionHandler
    def on_inv_transaction(hash)
      p ['inv transaction', hash.hth]
      pkt = Bitcoin::Protocol.getdata_pkt(:tx, [hash])
      send_data(pkt)
    end

    def on_inv_block(hash)
      p ['inv block', hash.hth]
      pkt = Bitcoin::Protocol.getdata_pkt(:block, [hash])
      send_data(pkt)
    end

    def on_get_transaction(hash)
      p ['get transaction', hash.hth]
    end

    def on_get_block(hash)
      p ['get block', hash.hth]
    end

    def on_addr(addr)
      p ['addr', addr, addr.alive?]
    end

    def on_tx(tx)
      p ['tx', tx.hash]
    end

    def on_ping(nonce)
      send_data(Bitcoin::Protocol.pong_pkt(nonce))
    end

    def on_block(block)
      p ['block', block.hash]
      #p block.payload.each_byte.map{|i| "%02x" % [i] }.join(" ")
      #puts block.to_json
    end

    def on_version(version)
      p [@sockaddr, 'version', version, version.time - Time.now.to_i]
      send_data( Bitcoin::Protocol.verack_pkt )
    end

    def on_verack
      on_handshake_complete
    end

    def on_handshake_complete
      p [@sockaddr, 'handshake complete']
      @connected = true

      query_blocks
    end

    def query_blocks
      start = ("\x00"*32)
      stop  = ("\x00"*32)
      pkt = Bitcoin::Protocol.pkt("getblocks", "\x00" + start + stop )
      send_data(pkt)
    end

    def on_handshake_begin
      pkt = Bitcoin::Protocol::Version.new(
        from:       "127.0.0.1:8333",
        to:         @sockaddr.join(":"),
      ).to_pkt
      p ['sending version pkt', pkt]
      send_data(pkt)
    end
  end


  class Connection < EM::Connection
    include ConnectionHandler

    def initialize(host, port, connections)
      @sockaddr = [host, port]
      @connections = connections
      @parser = Bitcoin::Protocol::Parser.new( self )
    end

    def post_init
      p ['connected', @sockaddr]
      EM.schedule{ on_handshake_begin }
    end

    def receive_data(data)
      @parser.parse(data)
    end

    def unbind
      p ['disconnected', @sockaddr]
      self.class.connect_random_from_dns(@connections)
    end

    def self.connect(host, port, connections)
      EM.connect(host, port, self, host, port, connections)
    end

    def self.connect_random_from_dns(connections)
      seeds = Bitcoin.network[:dns_seeds]
      if seeds.any?
        host = Resolv::DNS.new.getaddresses(seeds.sample).map {|a| a.to_s}.sample
        connect(host, Bitcoin::network[:default_port], connections)
      else
        raise "No DNS seeds available. Provide IP, configure seeds, or use different network."
      end
    end
  end
end

if $0 == __FILE__
  EM.run do
    connections = []
    #Bitcoin::Connection.connect('127.0.0.1', 8333, connections)
    EM::Bitcoin::Connection.connect_random_from_dns(connections)
  end
end
