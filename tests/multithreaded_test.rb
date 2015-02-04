require "cutest"
require_relative "../lib/redic"

REDIS_URL = "redis://localhost:6379/"

prepare do
  Redic.new(REDIS_URL).call("FLUSHDB")
end

test "multiple threads" do

  cs = Array.new

  c = Redic.new(REDIS_URL)

  c.queue("SET", "foo", "1")

  t1 = Thread.new do
    c.queue("SET", "bar", "2")
  end

  t2 = Thread.new do
    c.queue("SET", "baz", "3")
    c.commit
  end

  t1.join
  t2.join

  assert_equal nil, c.call("GET", "foo")
  assert_equal nil, c.call("GET", "bar")
  assert_equal "3", c.call("GET", "baz")

  c.commit

  assert_equal "1", c.call("GET", "foo")
end
