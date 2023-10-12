# frozen_string_literal: true

module SidekiqStatusMonitor
  class Config
    include Singleton

    attr_accessor :host,
                  :port,
                  :path,
                  :server,
                  :logger,
                  :shutdown_callback,
                  :workers_size_threshold,
                  :process_set_size_threshold,
                  :queues_size_threshold,
                  :queue_latency_threshold,
                  :queue_size_threshold

    def initialize
      set_defaults
    end

    def set_defaults
      @logger = Sidekiq.logger

      @host = ENV.fetch("SIDEKIQ_STATUS_HOST", "0.0.0.0")
      @port = ENV.fetch("SIDEKIQ_STATUS_PORT", 7433)
      @server = ENV.fetch("SIDEKIQ_STATUS_SERVER", "webrick")

      @shutdown_callback = proc {}

      @workers_size_threshold = 0
      @process_set_size_threshold = 1
      @queues_size_threshold = 1
      @queue_latency_threshold = 30 * 60
      @queue_size_threshold = 1_000_000
    end
  end
end
