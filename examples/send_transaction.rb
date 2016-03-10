$LOAD_PATH << "../lib"
require 'em_bitcoin'

# This class is using bitcoin-ruby's Builder API
class TransactionFactory
  extend Bitcoin::Builder

  def self.create_tx
    # the previous transaction that has an output to your address
    prev_hash = "5...0"

    # the number of the output you want to use
    prev_out_index = 0

    # fetch the tx from whereever you like and parse it
    prev_tx = Bitcoin::P::Tx.from_json(open("http://webbtc.com/tx/#{prev_hash}.json"))

    # my address is 1Bad6NVjs8nwvizG7s5asQrLSM7GW3sChf (last used in keys.txt)
    # the key needed to sign an input that spends the previous output
    key = Bitcoin::Key.new("8...4", "0......f")

    # This comes from Bitcoin::Builder...
    new_tx = build_tx do |tx|
      # add the input you picked out earlier
      tx.input do |i|
        i.prev_out prev_tx
        i.prev_out_index prev_out_index
        i.signature_key key
      end

      # add an output that sends some bitcoins to another address
      tx.output do |o|
        o.value 30000 # in satoshis
        # Next unused address in keys.txt
        o.script {|s| s.recipient "1....6" }
      end
    end

    # examine your transaction. you can relay it through http://test.webbtc.com/relay_tx
    # that will also give you a hint on the error if something goes wrong
    puts "SAVE this tx hash!!!"
    puts "v"*40
    puts new_tx.to_json
    puts "^"*40

    new_tx
  end
end

# EM::Bitcoin::Connection.user_agent = "redsquirrel.com/btc"

# tx = TransactionFactory.create_tx
tx = "fakeTX"

class TransactionPusher < EM::Bitcoin::Connection
  attr_reader :tx

  after_handshake :send_tx 

  private

  def send_tx
    puts "Sending transaction to #{self.address}!"
    p tx
    # send_data(Bitcoin::Protocol.pkt("tx", self.tx.payload))
    close_connection
  end
end

EM.run do
  # show against testnet
  EM::Bitcoin::Connection.connect(TransactionPusher, tx: tx)
end
