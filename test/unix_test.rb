require File.expand_path("../lib/redic", File.dirname(__FILE__))

setup do
  Redic.new("unix:///tmp/redis.sock")
end

test "normal commands" do |c|
  c.call("SET", "foo", "bar")

  assert_equal "bar", c.call("GET", "foo")
end

test "pipelining" do |c|
  c.pipe("SET", "foo", "bar")
  c.pipe("GET", "foo")

  assert_equal ["OK", "bar"], c.run
end

test "multi/exec" do |c|
  c.pipe("MULTI")
  c.pipe("SET", "foo", "bar")
  c.pipe("EXEC")

  assert_equal ["OK", "QUEUED", ["OK"]], c.run
end
