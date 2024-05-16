# frozen_string_literal: true

require "rack/test"
require "net/http"

RSpec.describe(SidekiqStatusMonitor::Server) do
  include Rack::Test::Methods

  subject(:app) { described_class.new }

  let(:info_response) do
    {
      alive: true,
      probe_workers_size: true,
      probe_process_set_size: false,
      probe_queues_size: false,
      probe_queue_avg_latency: nil,
      probe_queue_avg_size: nil
    }
  end

  describe "#run!" do
    subject { app.run! }

    before { allow(Rack::Handler).to(receive(:get).with("webrick").and_return(fake_webrick)) }

    let(:fake_webrick) { double }

    it "runs the handler with sidekiq_status_monitor logger, host and no access logs" do
      expect(fake_webrick).to(receive(:run).with(
        app,
        hash_including(
          Logger: SidekiqStatusMonitor.logger,
          Host: "0.0.0.0",
          Port: 7433,
          AccessLog: []
        )
      ))

      subject
    end

    context "when we change the host config" do
      around do |example|
        ENV["SIDEKIQ_STATUS_HOST"] = "1.2.3.4"
        SidekiqStatusMonitor.config.set_defaults

        example.run

        ENV["SIDEKIQ_STATUS_HOST"] = nil
      end

      it "respects the SIDEKIQ_STATUS_HOST environment variable" do
        expect(fake_webrick).to(receive(:run).with(
          described_class,
          hash_including(Host: "1.2.3.4")
        ))

        subject
      end
    end
  end

  describe "responses" do
    context "when service is alive" do
      before do
        allow(SidekiqStatusMonitor).to(receive(:alive?) { true })
      end
      it "responds with success when the service is alive" do
        get "/"
        expect(last_response).to(be_ok)
        expect(JSON.parse(last_response.body, symbolize_names: true)).to(eq(info_response))
      end
    end

    context "when service is not alive" do
      before do
        allow(SidekiqStatusMonitor).to(receive(:alive?) { false })
      end
      it "responds to random path" do
        get "/unknown-path"
        expect(last_response).not_to(be_ok)
        expect(JSON.parse(last_response.body, symbolize_names: true)).to(eq(info_response.merge(alive: false)))
      end
    end
  end

  describe "SidekiqStatusMonitor setup host" do
    subject(:host) { app.host }

    before do
      ENV["SIDEKIQ_STATUS_HOST"] = "1.2.3.4"
      SidekiqStatusMonitor.config.set_defaults
    end

    after do
      ENV["SIDEKIQ_STATUS_HOST"] = nil
    end

    it "respects the SIDEKIQ_STATUS_HOST environment variable" do
      expect(host).to(eq("1.2.3.4"))
    end
  end

  describe "SidekiqStatusMonitor setup port" do
    subject(:port) { app.port }

    before do
      ENV["SIDEKIQ_STATUS_PORT"] = "4567"
      SidekiqStatusMonitor.config.set_defaults
    end

    after do
      ENV["SIDEKIQ_STATUS_PORT"] = nil
    end

    it "respects the SIDEKIQ_STATUS_PORT environment variable" do
      expect(port).to(eq("4567"))
    end
  end

  describe "SidekiqStatusMonitor setup server" do
    subject(:server) { app.engine }

    before do
      ENV["SIDEKIQ_STATUS_SERVER"] = "puma"
      SidekiqStatusMonitor.config.set_defaults
    end

    after do
      ENV["SIDEKIQ_STATUS_SERVER"] = nil
    end

    it "respects the SIDEKIQ_STATUS_PORT environment variable" do
      expect(server).to(eq("puma"))
    end
  end

  describe "SidekiqStatusMonitor setup path" do
    it "responds ok on any path" do
      allow(SidekiqStatusMonitor).to(receive(:alive?) { true })
      get "/sidekiq-probe"
      expect(last_response).to(be_ok)
    end
  end
end
