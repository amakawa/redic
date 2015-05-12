require "cutest"
require_relative "../lib/redic"

REDIS_URL = "redis://localhost:6379/"

prepare do
  c = Redic.new(REDIS_URL)

  begin
    c.call!("FLUSHDB").inspect
  rescue
    c.call!("AUTH", "foo")
    c.call!("SELECT", "0")
    c.call!("FLUSHDB")
    c.call!("CONFIG", "SET", "requirepass", "")
  end
end

setup do
  Redic.new(REDIS_URL)
end

test "url" do |c|
  assert_equal "redis://localhost:6379/", c.url
end

test "select db from url" do |c1|

  # Connect to db 1
  c2 = Redic.new("redis://localhost:6379/2")

  c2.call("FLUSHDB")

  # Set a value in db 0
  c1.call("SET", "foo", "bar")

  assert_equal(1, c1.call("DBSIZE"))
  assert_equal(0, c2.call("DBSIZE"))
end

test "error when selecting db from url" do
  c2 = Redic.new("redis://localhost:6379/foo")

  assert_raise(RuntimeError) do

    # Connection is lazy, send a command
    c2.call("PING")
  end
end

test "error when authenticating from url" do |c1|

  # Configure password as "foo"
  c1.call("CONFIG", "SET", "requirepass", "foo")

  # The password provided is wrong
  c2 = Redic.new("redis://:bar@localhost:6379/")

  assert_raise(RuntimeError) do

    # Connection is lazy, send a command
    c2.call("PING")
  end

  c3 = Redic.new("redis://:foo@localhost:6379/")
  assert_equal "PONG", c3.call("PING")

  # Remove password
  c3.call("CONFIG", "SET", "requirepass", "")
end

test "Can connect to sentinel" do
  c2 = Redic.new "redis://localhost:26379"
  c2.call "SENTINEL", "masters"
end

test "timeout" do |c1|

  # Default timeout is 10 seconds
  assert_equal 10_000_000, c1.timeout

  # Timeout configured to 200_000 microseconds
  c2 = Redic.new(REDIS_URL, 200_000)

  assert_equal 200_000, c2.timeout
end

test "normal commands" do |c|
  c.call("SET", "foo", "bar")

  assert_equal "bar", c.call("GET", "foo")
end

test "pipelining" do |c|
  c.queue("SET", "foo", "bar")
  c.queue("GET", "foo")

  assert_equal ["OK", "bar"], c.commit
end

test "multi/exec" do |c|
  c.queue("MULTI")
  c.queue("SET", "foo", "bar")
  c.queue("EXEC")

  assert_equal ["OK", "QUEUED", ["OK"]], c.commit
end

test "runtime errors" do |c|
  res = c.call("KABLAMMO")

  assert res.is_a?(RuntimeError)
end

test "encoding" do |c|
  Encoding.default_external = "UTF-8"

  c.call("SET", "foo", "שלום")

  assert_equal "Shalom שלום", "Shalom " + c.call("GET", "foo")

end if defined?(Encoding)

test "errors in pipeline" do |c|
  c.queue("SET", "foo", "bar")
  c.queue("INCR", "foo")
  c.queue("GET", "foo")

  res = c.commit

  assert "OK" == res[0]
  assert RuntimeError === res[1]
  assert "bar" == res[2]
end

test "thread safety" do |c|
  c.call("SET", "foo", 1)
  c.call("SET", "bar", 2)

  foos, bars = nil, nil

  t1 = Thread.new do
    foos = Array.new(100) { c.call("GET", "foo") }
  end

  t2 = Thread.new do
    bars = Array.new(100) { c.call("GET", "bar") }
  end

  t1.join
  t2.join

  assert_equal ["1"], foos.uniq
  assert_equal ["2"], bars.uniq
end

test "blocking commands" do |c1|
  c2 = Redic.new
  r = nil

  t1 = Thread.new do
    r = c1.call("BLPOP", "foo", 5)
  end

  t2 = Thread.new do
    c2.call("RPUSH", "foo", "value")
  end

  t1.join
  t2.join

  assert_equal ["foo", "value"], r
end

test "pub/sub" do |c1|
  c2 = Redic.new

  assert_equal ["subscribe", "foo", 1], c1.call("SUBSCRIBE", "foo")

  c2.call("PUBLISH", "foo", "value1")
  c2.call("PUBLISH", "foo", "value2")

  assert_equal ["message", "foo", "value1"], c1.client.read
  assert_equal ["message", "foo", "value2"], c1.client.read

  c1.call("UNSUBSCRIBE", "foo")

  assert_equal "PONG", c1.call("PING")
end

test "reconnect" do |c1|
  url = "redis://:foo@localhost:6379/"

  assert url != c1.url

  c1.call("CONFIG", "SET", "requirepass", "foo")

  c1.configure(url)

  assert url == c1.url
  assert url.object_id == c1.url.object_id

  # Reconfigure only if URLs differ
  c1.configure(url.dup)

  # No reconnection ocurred
  assert url.object_id == c1.url.object_id

  assert_equal "PONG", c1.call("PING")
end

test "disconnect" do |c1|

  # Connection is lazy
  assert_equal false, c1.client.connected?
  assert_equal false, c1.quit

  c1.call("PING")

  assert_equal true, c1.client.connected?
  assert_equal true, c1.quit

  assert_equal false, c1.client.connected?
end
