require File.expand_path("../lib/redic", File.dirname(__FILE__))

setup do
  Redic.new
end

test "url" do |c|
  assert_equal "redis://127.0.0.1:6379", c.url
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

test "runtime errors" do |c|
  assert_raise RuntimeError do
    c.call("KABLAMMO")
  end
end
