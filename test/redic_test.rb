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
  res = c.call("KABLAMMO")

  assert res.is_a?(RuntimeError)
end

test "encoding" do |c|
  Encoding.default_external = "UTF-8"

  c.call("SET", "foo", "שלום")

  assert_equal "Shalom שלום", "Shalom " + c.call("GET", "foo")

end if defined?(Encoding)

test "errors in pipeline" do |c|
  c.write("SET", "foo", "bar")
  c.write("INCR", "foo")
  c.write("GET", "foo")

  res = c.run

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
