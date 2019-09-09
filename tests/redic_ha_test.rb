require "cutest"
require_relative "../lib/redic_ha"
require_relative "../lib/redic"

prepare do
  RedicHA.new(ENV['MASTER_NAME'], ENV['SENTINEL_URL']).call("FLUSHDB")
end

setup do
  RedicHA.new(ENV['MASTER_NAME'], ENV['SENTINEL_URL'])
end

test "test_failover_handling" do |c|
  10.times do
    assert_equal "OK", c.call(:set, :foo, :bar)
  end

  # Simulate failover
  c2 = Redic.new ENV['SENTINEL_URL']
  c2.call :sentinel, :failover, :test

  10.times do
    assert_equal "OK", c.call(:set, :foo, :bar)
  end
end