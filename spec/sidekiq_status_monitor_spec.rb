# frozen_string_literal: true

begin
  # this is needed for spec to work with sidekiq >7
  require "sidekiq/capsule"
rescue LoadError # rubocop:disable Lint/SuppressedException
end

RSpec.describe(SidekiqStatusMonitor) do
  context "with configuration" do
    it "has a version number" do
      expect(SidekiqStatusMonitor::VERSION).not_to(be(nil))
    end

    it "configures the host from the #setup" do
      described_class.setup do |config|
        config.host = "1.2.3.4"
      end

      expect(described_class.config.host).to(eq("1.2.3.4"))
    end

    it "configures the host from the SIDEKIQ_STATUS_HOST ENV var" do
      ENV["SIDEKIQ_STATUS_HOST"] = "1.2.3.4"

      SidekiqStatusMonitor.config.set_defaults

      expect(described_class.config.host).to(eq("1.2.3.4"))

      ENV["SIDEKIQ_STATUS_HOST"] = nil
    end

    it "configures the port from the #setup" do
      described_class.setup do |config|
        config.port = 4567
      end

      expect(described_class.config.port).to(eq(4567))
    end

    it "configures the port from the SIDEKIQ_STATUS_PORT ENV var" do
      ENV["SIDEKIQ_STATUS_PORT"] = "4567"

      SidekiqStatusMonitor.config.set_defaults

      expect(described_class.config.port).to(eq("4567"))

      ENV["SIDEKIQ_STATUS_PORT"] = nil
    end

    it "configurations behave as expected" do
      k = described_class.config

      expect(k.host).to(eq("0.0.0.0"))
      k.host = "1.2.3.4"
      expect(k.host).to(eq("1.2.3.4"))

      expect(k.port).to(eq(7433))
      k.port = 4567
      expect(k.port).to(eq(4567))

      expect(k.shutdown_callback.call).to(eq(nil))
      k.shutdown_callback = proc { "hello" }
      expect(k.shutdown_callback.call).to(eq("hello"))
    end
  end

  context "with redis" do
    let(:sidekiq_7) { SidekiqStatusMonitor::Helpers.sidekiq_7 }
    # Older versions of sidekiq yielded Sidekiq module as configuration object
    # With sidekiq > 7, configuration is a separate class
    let(:sq_config) { sidekiq_7 ? Sidekiq.default_configuration : Sidekiq }

    before do
      allow(Sidekiq).to(receive(:server?) { true })
      allow(sq_config).to(receive(:on))

      if sidekiq_7
        allow(sq_config).to(receive(:capsule).and_call_original)
      elsif sq_config.respond_to?(:[])
        allow(sq_config).to(receive(:[]).and_call_original)
      else
        allow(sq_config).to(receive(:options).and_call_original)
      end
    end

    it "::hostname" do
      expect(SidekiqStatusMonitor.hostname).to(eq("test-hostname"))
    end

    describe ".alive?" do
      context "when all conditions satisfied" do
        before do
          allow(SidekiqStatusMonitor).to(receive(:queues_avg_latency) { 0 })
          allow(SidekiqStatusMonitor).to(receive(:workers_size) { 0 })
          allow(SidekiqStatusMonitor).to(receive(:process_set_size) { 1 })
          allow(SidekiqStatusMonitor).to(receive(:queues_size) { 1 })
          allow(SidekiqStatusMonitor).to(receive(:queues_avg_size) { 0 })
        end
        it "returns true" do
          expect(SidekiqStatusMonitor.alive?).to(be_truthy)
        end
        it "returns info" do
          expect(SidekiqStatusMonitor.info).to(eq(
            alive: true,
            probe_workers_size: true,
            probe_process_set_size: true,
            probe_queues_size: true,
            probe_queue_avg_latency: true,
            probe_queue_avg_size: true
          ))
        end
      end
    end

    describe "#start" do
      before do
        allow(SidekiqStatusMonitor).to(receive(:fork) { 1 })
        allow(sq_config).to(receive(:on).with(:startup) { |&arg| arg.call })

        SidekiqStatusMonitor.instance_variable_set(:@redis, nil)
      end
    end
  end
end
