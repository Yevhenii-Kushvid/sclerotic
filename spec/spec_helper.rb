require File.expand_path("../../lib/sclerotic.rb", __FILE__)
require "fakeredis/rspec"
require "timecop"

SECONDS_IN_DAY = 24 * 60 * 60
DAY = SECONDS_IN_DAY
WEEK = 7 * SECONDS_IN_DAY
MONTH = 30 * DAY

RSpec.configure do |c|
  c.before(:all) do
    Sclerotic.redis = Redis.new
  end

  c.after(:each) do
    Redis.current.flushdb
  end
end
