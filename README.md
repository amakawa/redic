Redic
=====

Lightweight Redis Client

Description
-----------

Lightweight Redis Client inspired by [redigo][redigo], a Redis
client library for golang.

## Usage

```ruby
# Accepts a Redis URL and defaults to "redis://127.0.0.1:6379".
redis = Redic.new

# Processes the command and returns the response.
redis.call("SET", "foo", "bar")

assert_equal "bar", redis.call("GET", "foo")

# Pipelining is implemented by buffering commands,
# then calling Redic#commit
redis.queue("SET", "foo", "bar")
redis.queue("GET", "foo")

assert_equal ["OK", "bar"], redis.commit
```

You can provide the password and the database to be selected. The
format for Redis URLs is "redis://user:pass@host:port/db". As
Redis only needs a password for authentication, the user can be
ommited:

```ruby
# Connect to localhost:6380 using "bar" as password and use the
# database 2. Both AUTH and SELECT commands are issued after
# connecting. The user part of the URL is not provided.
redis = Redic.new("redis://:bar@localhost:6380/2")
```

It is also possible to configure a timeout for the connection. The
default timeout is 10 seconds.

```ruby
# Timeout expressed in microseconds.
redis = Redic.new(timeout: 2_000_000)
```

Here's one final example using both a Redis URL and a timeout:

```ruby
# It's recommended to store the REDIS_URL as an environment
# variable. Use `fetch` to retrieve values that must be present,
# as it raises an error if the value is not found.
REDIS_URL = ENV.fetch("REDIS_URL")
REDIS_TIMEOUT = ENV.fetch("REDIS_TIMEOUT")

redis = Redic.new(REDIS_URL, timeout: REDIS_TIMEOUT)
```

## Differences with redis-rb

Redic uses [hiredis][hiredis] for the connection and for parsing
the replies. There are no alternative connection drivers. Unlike
[redis-rb][redis-rb] it doesn't define all the Redis commands, and
instead it acts as a transport layer. The lock provided is smaller
than that of redis-rb, as it only wraps the writing and reading from
the connection. So even if both clients are thread-safe by default,
the peformance of a smaller lock is marginally better.

[redigo]: https://github.com/garyburd/redigo
[hiredis]: https://github.com/pietern/hiredis-rb
[redis-rb]: https://github.com/redis/redis-rb

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
