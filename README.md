Sclerotic
=======

Sclerotic is a scalable trending library designed to track temporal trends in non-stationary categorical distributions. 

## Installation

Add to Gemfile:

```ruby
gem "sclerotic", github: "Yevhenii-Kushvid/sclerotic"
```

Usage
-----

Take, for example, a social network in which users can follow each other. You want to track trending users. You construct a one week delta, to capture trends in your follows data over one week periods:

for time input you can use `1.week` or value in seconds `60 * 60 * 24 * 7`

```ruby
trended_searches = Sclerotic::Delta.create('search_trend', t: 1.week, replay: true)
```

in addition you can set cache reate for more straight forwad, fast read operation
recalcularion of items time stams and clearens of sets operates ON READ operation `fetch`

```ruby
trended_searches = Sclerotic::Delta.create('search_trend', t: 1.week, replay: true, cache: 24.hours)
```
The delta consists of two sets of counters indexed by category identifiers. In this example, the identifiers will be user ids. One set decays over the mean lifetime specified by _t_, and another set decays over double the lifetime.

You can now add observations to the delta, in the form of follow events. Each time a user follows another, you increment the followed user id. We can also do this retrospectively, since we have passed the `replay` option to the factory method above:
```ruby
trended_searches = Sclerotic::Delta.fetch('search_trend')
trended_searches.incr('Donald Trump', 10000)
trended_searches.incr('Barack Obama', date: 10.days.ago)
trended_searches.incr_by('George W. Bush', 4)
trended_searches.incr('Bill Clinton') # defalut increment rate is 1
trended_searches.incr('George H. W. Bush')
```
Providing an explicit date is useful if you are processing data asynchronously. You can also use `incr_by` to increment a counter in batches.

You can now consult your follows delta to find your top trending users:
```ruby
puts trended_searches.fetch
```
Will print:
```ruby
{ 'Donald Trump' => 0.667, 'Barack Obama' => 0.500 }
```
Each user is given a dimensionless score in the range 0..1 corresponding to the normalised follows delta over the time period. This expresses the proportion of follows gained by the user over the last week compared to double that lifetime.

Optionally fetch the top _n_ users, or an individual user's trending score:
```ruby
trended_searches.fetch(n: 20)
trended_searches.fetch(bin: 'Barack Obama')
```

## Custom Setup

Sclerotic will default to using `Redis.current` for Redis commands, but can be
configured to use a specific Redis client:

```ruby
Sclerotic.redis = Redis.new(host: "10.0.1.1", port: 6380, db: 15)
```

or a hash of options that will be passed to `Redis.new`:

```ruby
Sclerotic.redis = { host: "10.0.1.1", port: 6380, db: 15 }
```

The hash options also support a special `namespace` key which will namespace all
Sclerotic keys under a prefix using the [redis-namespace][] gem. For example:

```ruby
Sclerotic.redis = { host: "localhost", port: 6379, db: 1, namespace: "sclerotic" }
```

which is equivalent to:

```ruby
require "redis-namespace"
client = Redis.new(host: "localhost", port: 6379, db: 1)
Sclerotic.redis = Redis::Namespace.new(:sclerotic, redis: client)
```

Note that if you are using the `namespace` key you are responsible for adding
the `redis-namespace` gem to your project's Gemfile - this gem doesn't
list it as a dependency.

Contributing
------------

Just fork the repo and submit a pull request.

About
------------------
It based on `forgesy gem`. Using a ratio of two such sets decaying over different lifetimes, it picks up on changes to recent dynamics in your observations, whilst forgetting historical data responsibly. The technique is closely related to exponential moving average (EMA) ratios used for detecting trends in financial data.

Trends are encapsulated by a construct named Delta. A Delta consists of two sets of counters, each of which implements exponential time decay of the form:

![equation](http://latex.codecogs.com/gif.latex?X_t_1%3DX_t_0%5Ctimes%7Be%5E%7B-%5Clambda%5Ctimes%7Bt%7D%7D%7D)

Where the inverse of the _decay rate_ (lambda) is the mean lifetime of an observation in the set. By normalising such a set by a set with half the decay rate, we obtain a trending score for each category in a distribution. This score expresses the change in the rate of observations of a category over the lifetime of the set, as a proportion in the range 0..1.

Sclerotic removes the need for manually sliding time windows or explicitly maintaining rolling counts, as observations naturally decay away over time. It's designed for heavy writes and sparse reads, as it implements decay at read time.

Each set is implemented as a redis `sorted set`, and keys are scrubbed when a count is decayed to near zero, providing storage efficiency.

Sclerotic handles distributions with upto around 10<sup>6</sup> active categories, receiving hundreds of writes per second, without much fuss. Its scalability is dependent on your redis deployment.


Copyright & License
-------------------
MIT license. See [LICENSE](LICENSE) for details.