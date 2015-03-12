require "cutest"
require_relative "../lib/redic"

REDIS_URL = "redis://localhost:6379/"

prepare do
  c = Redic.new(REDIS_URL)

  begin
    c.call("FLUSHDB")
  rescue
    c.call("AUTH", "foo")
    c.call("FLUSHDB")
    c.call("CONFIG", "SET", "requirepass", "")
  end
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

  # The buffer for `c` still exists
  assert_equal "1", c.call("GET", "foo")

  # Buffer for the thread that didn't commit is the only one left
  assert_equal 1, c.instance_variable_get("@buffer").keys.size

  c.clear

  # All buffers are cleared
  assert_equal 0, c.instance_variable_get("@buffer").keys.size
end
