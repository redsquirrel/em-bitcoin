# EM-Bitcoin

The [Bitcoin protocol](https://en.bitcoin.it/wiki/Protocol_documentation) implemented using Ruby's [EventMachine](https://github.com/eventmachine/eventmachine). Initially extracted from [bitcoin-ruby](https://github.com/lian/bitcoin-ruby).

## Using `EventMachine::Bitcoin::Connection` to connect to the Bitcoin network

```ruby
require 'em_bitcoin'
```

```ruby
gem 'em-bitcoin'
```

Remember that you always need to start the EventMachine event loop. You can't just do this:

```ruby
EventMachine::Bitcoin::Connection.connect_random_from_dns
```

You'll need to do this, which will actually connect to the Bitcoin network and you'll see a stream of transactions.

```ruby
EventMachine.run do
  EventMachine::Bitcoin::Connection.connect_random_from_dns
end
```

You can override the [EventMachine::Connection](http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine/Connection) methods to provide your application-specific logic. Such as:

```ruby
class TxCounter < EventMachine::Bitcoin::Connection
  def post_init
    super
    @tx_count = 0
  end

  def receive_data(data)
    super
    @tx_count += 1
  end

  def unbind
    puts "Total transactions were: #{@tx_count}!"
  end
end

EM.run { TxCounter.connect_random_from_dns }
```

## TODO

* Rework the integration points to both EM and the Bitcoin protocol parser
* Warn about some of the DNS seeds being flaky
* Write some tests
* Write some examples

## License

Available here: [COPYING](COPYING.txt)
