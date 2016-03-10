module EM::Bitcoin
  module ConnectionHandler
    def on_inv_transaction(hash)
      # p ['inv transaction', hash.hth]
      pkt = Bitcoin::Protocol.getdata_pkt(:tx, [hash])
      send_data(pkt)
    end

    def on_inv_block(hash)
      # p ['inv block', hash.hth]
      pkt = Bitcoin::Protocol.getdata_pkt(:block, [hash])
      send_data(pkt)
    end

    def on_get_transaction(hash)
      # p ['get transaction', hash.hth]
    end

    def on_get_block(hash)
      # p ['get block', hash.hth]
    end

    def on_addr(addr)
      # p ['addr', addr, addr.alive?]
    end

    def on_tx(tx)
      # p ['tx', tx.hash]
      return if self.class.after_transaction_handlers.nil?

      self.class.after_transaction_handlers.each do |handler|
        EM.schedule do
          send(handler, tx)
        end
      end
    end

    def on_ping(nonce)
      send_data(Bitcoin::Protocol.pong_pkt(nonce))
    end

    def on_block(block)
      # p ['block', block.hash]
    end

    def on_version(version)
      # p [@sockaddr, 'version', version, version.time - Time.now.to_i]
      send_data(Bitcoin::Protocol.verack_pkt)
    end

    def on_verack
      on_handshake_complete
    end

    def on_handshake_complete
      p [@sockaddr, 'handshake complete']

      # @connected = true
      # query_blocks

      return if self.class.after_handshake_handlers.nil?

      self.class.after_handshake_handlers.each do |handler|
        EM.schedule do
          send(handler)
        end
      end
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
        # user_agent: self.class.user_agent,
      ).to_pkt
      # p ['sending version pkt', pkt]
      send_data(pkt)
    end
  end

  class Connection < EM::Connection
    include ConnectionHandler

    class << self
      attr_accessor :user_agent

      attr_reader :after_handshake_handlers
      def after_handshake(method_name)
        @after_handshake_handlers ||= []
        @after_handshake_handlers << method_name
      end

      attr_reader :after_transaction_handlers
      def after_transaction(method_name)
        @after_transaction_handlers ||= []
        @after_transaction_handlers << method_name
      end
    end

    attr_reader :address
    def initialize(address, args = {})
      @address = address
      @sockaddr = [address, 8333]

      args.each do |k, v|
        instance_variable_set("@"+k.to_s, v)
      end

      @parser = Bitcoin::Protocol::Parser.new(self)
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
    end

    def self.connect(handler, args = {})   
      seed = Bitcoin.network[:dns_seeds].sample
      # puts "Grabbing addresses based on seed: " + seed
      addresses = Resolv::DNS.new.getresources(seed, Resolv::DNS::Resource::IN::A).map {|r|r.address.to_s}
        
      addresses.each do |address|
        # puts "Attempting to connect to " + address
        EM.connect(address, 8333, handler, address, args)
      end
    end
  end
end
