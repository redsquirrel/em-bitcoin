$LOAD_PATH << "../lib"
require 'em_bitcoin'

class TransactionListener < EM::Bitcoin::Connection
  attr_reader :database

  after_transaction :filter_and_print

  private

  def filter_and_print(tx)
    return if database.include?(tx.hash)
    database << tx.hash
    puts tx.hash
  end
end

EM.run do
  EM::Bitcoin::Connection.connect(TransactionListener, database: [])
end
