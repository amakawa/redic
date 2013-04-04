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
# Accepts the same options as Redis.new
redis = Redic.new

# Processes the command and returns the response.
redis.call("SET", "foo", "bar")

assert_equal "bar", redis.call("GET", "foo")

# Pipelining is implemented by buffering commands,
# then calling Redic#run
redis.write("SET", "foo", "bar")
redis.write("GET", "foo")

assert_equal ["OK", "bar"], redis.run
```

## Installation

You can install it using rubygems.

```
$ gem install redic
```
