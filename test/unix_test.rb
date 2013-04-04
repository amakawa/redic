require File.expand_path("../lib/redic", File.dirname(__FILE__))

setup do
  Redic.new(url: "unix:///tmp/redis.sock")
end

test "normal commands" do |c|
  c.call("SET", "foo", "bar")

  assert_equal "bar", c.call("GET", "foo")
end

test "pipelining" do |c|
  c.write("SET", "foo", "bar")
  c.write("GET", "foo")

  assert_equal ["OK", "bar"], c.run
end

test "multi/exec" do |c|
  c.write("MULTI")
  c.write("SET", "foo", "bar")
  c.write("EXEC")

  assert_equal ["OK", "QUEUED", ["OK"]], c.run
end
