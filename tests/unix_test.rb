require "cutest"
require_relative "../lib/redic"

setup do
  Redic.new("unix:///tmp/redis.sock")
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
