Redic
=====

Lightweight Redis Client

Description
-----------

Wrapper for `Redis::Client` that avoids rubyisms. It is inspired
by [redigo](https://github.com/garyburd/redigo), a Redis client
library for golang.

## Usage

```ruby
# Accepts the same options as Redis.new
redis = Redic.new

# Processes the command and returns the response.
c.call("SET", "foo", "bar")

assert_equal "bar", c.call("GET", "foo")

# Pipelining is implemented by buffering commands,
# then calling Redic#run
c.write("SET", "foo", "bar")
c.write("GET", "foo")

assert_equal ["OK", "bar"], c.run
```

## Installation

You can install it using rubygems.

```
$ gem install redic
```
