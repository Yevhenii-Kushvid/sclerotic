require "spec_helper"

def redis_params(r)
  r.options.select{|k,_| [:url, :host, :port, :db].include?(k)}
end

describe "Sclerotic" do
  describe "connection" do
    before do
      @conn_backup = Sclerotic.instance_variable_get(:@redis)
      Sclerotic.remove_instance_variable(:@redis)
    end
    after do
      Sclerotic.instance_variable_set(:@redis, @conn_backup)
    end

    describe "without connection params provided" do
      it "creates a default client using Redis.current" do
        expect(Sclerotic.redis).to be(Redis.current)
        expect(Sclerotic.redis).to be_a(::Redis)
        expect(redis_params(Sclerotic.redis)).to eq({
          url: nil,
          host: "127.0.0.1",
          port: 6379,
          db: 0,
        })
      end
    end

    describe "with connection params provided" do
      before do
        Sclerotic.redis = redis_opts
      end

      describe "using a Redis instance" do
        let(:redis_opts) { Redis.new(url: "redis://localhost:6380/5") }

        it "sets up client correctly" do
          expect(Sclerotic.redis).to be_a(::Redis)
          expect(redis_params(Sclerotic.redis)).to eq({
            url: "redis://localhost:6380/5",
            host: "localhost",
            port: 6380,
            db: 5,
          })
        end
      end

      describe "using a params hash without namespace" do
        let(:redis_opts) { {host: "10.0.1.1", db: 3} }

        it "sets up client correctly" do
          expect(Sclerotic.redis).to be_a(::Redis)
          expect(redis_params(Sclerotic.redis)).to eq({
            url: nil,
            host: "10.0.1.1",
            port: 6379,
            db: 3,
          })
        end
      end

      describe "using a params hash with namespace" do
        let(:redis_opts) { {host: "10.0.1.2", port: 6381, db: 2, namespace: "foo"} }

        it "sets up client correctly" do
          expect(Sclerotic.redis).to be_a(::Redis::Namespace)
          expect(Sclerotic.redis.namespace).to eq("foo")
          expect(Sclerotic.redis.redis).to be_a(::Redis)
          expect(redis_params(Sclerotic.redis.redis)).to eq({
            url: nil,
            host: "10.0.1.2",
            port: 6381,
            db: 2,
          })
        end
      end
    end
  end
end
