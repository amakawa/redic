Redic
=====

Lightweight Redis Client

Description
-----------

Lightweight Redis Client inspired by
[redigo](https://github.com/garyburd/redigo), a Redis client
library for golang.

## Usage

```ruby
# Accepts a Redis URL and defaults to "redis://127.0.0.1:6379".
redis = Redic.new

# Processes the command and returns the response.
redis.call("SET", "foo", "bar")

assert_equal "bar", redis.call("GET", "foo")

# Pipelining is implemented by buffering commands,
# then calling Redic#run
redis.pipe("SET", "foo", "bar")
redis.pipe("GET", "foo")

assert_equal ["OK", "bar"], redis.run
```

## Differences with redis-rb

Redic uses [hiredis][hiredis] for the connection and for parsing
the replies. There are no alternative connection drivers. Unlike
[redis-rb][redis-rb] it doesn't define all the Redis commands, and
instead it acts as a transport layer. The lock provided is smaller
than that of redis-rb, as it only wraps the writing and reading from
the connection. So even if both clients are thread-safe by default,
the peformance of a smaller lock is marginally better.

## Limitations

When a client enters a subscribed mode, further reads to retrieve the
messages are not thread safe. It is very important to take this into
account and to create a different client if you need to send different
operations while a client is subscribed to a channel.

```ruby
# Example of pub/sub usage.
c1 = Redic.new
c2 = Redic.new

# After this command, the client is no longer thread safe.
c1.call("SUBSCRIBE", "foo")

# That's why we need to publish from a different connection.
c2.call("PUBLISH", "foo")

# Note that this operation is not thread safe.
assert_equal ["message", "foo", "value1"], c1.client.read
```

You can wrap thread unsafe operations in a mutex:

```ruby
redis = Redic.new

mutex = Mutex.new

mutex.synchronize do
  redis.call("MONITOR")

  # Display every command sent to Redis.
  loop do
    puts redis.client.read
  end
end
```

## Installation

You can install it using rubygems.

```
$ gem install redic
```
