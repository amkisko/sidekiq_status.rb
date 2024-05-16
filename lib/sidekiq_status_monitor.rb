# frozen_string_literal: true

require "singleton"

require "sidekiq"
require "sidekiq/api"

require "sidekiq_status_monitor/version"

require "sidekiq_status_monitor/config"

require "sidekiq_status_monitor/server"
require "sidekiq_status_monitor/redis"
require "sidekiq_status_monitor/helpers"

module SidekiqStatusMonitor
  CAPSULE_NAME = "sidekiq-status"
  PROBE_METHOD_PREFIX = "probe_"

  class << self
    def start
      Sidekiq.configure_server do |sidekiq_config|
        sidekiq_config.on(:startup) do
          logger.info("Starting SidekiqStatusMonitor #{SidekiqStatusMonitor::VERSION}")

          @server_pid = fork do
            SidekiqStatusMonitor::Server.new.run!
          end

          logger.info("SidekiqStatusMonitor started, #{config.server} pid #{@server_pid}")
        end

        sidekiq_config.on(:quiet) do
          config.shutdown_callback.call
        end

        sidekiq_config.on(:shutdown) do
          Process.kill("TERM", @server_pid) unless @server_pid.nil?
          Process.wait(@server_pid) unless @server_pid.nil?

          config.shutdown_callback.call

          logger.info("SidekiqStatusMonitor stopped")
        end
      end
    end

    def setup
      yield(config)
    end

    def redis
      @redis ||= SidekiqStatusMonitor::Redis.adapter
    end

    def logger
      config.logger || Sidekiq.logger
    end

    def config
      @config ||= SidekiqStatusMonitor::Config.instance
    end

    def hostname
      ENV["HOSTNAME"] || "HOSTNAME_NOT_SET"
    end

    def workers
      Sidekiq::Workers.new
    end

    def workers_size
      workers.size
    end

    def process_set
      Sidekiq::ProcessSet.new
    end

    def process_set_size
      process_set.size
    end

    def queues
      Sidekiq::Queue.all
    end

    def queues_size
      queues.size
    end

    def queues_avg_latency
      queues.sum(&:latency) / queues_size if queues_size&.positive?
    end

    def queues_avg_size
      queues.sum(&:size) / queues_size if queues_size&.positive?
    end

    def queues_names
      queues.map(&:name).uniq.sort
    end

    def self.new_probe(name, &)
      define_method(:"#{PROBE_METHOD_PREFIX}#{name}", &)
    end

    new_probe :workers_size do
      !config.workers_size_threshold || workers_size && workers_size >= config.workers_size_threshold
    end

    new_probe :process_set_size do
      !config.process_set_size_threshold || process_set_size && process_set_size >= config.process_set_size_threshold
    end

    new_probe :queues_size do
      !config.queues_size_threshold || queues_size && queues_size >= config.queues_size_threshold
    end

    new_probe :queue_avg_latency do
      !config.queue_latency_threshold || queues_avg_latency && queues_avg_latency < config.queue_latency_threshold
    end

    new_probe :queue_avg_size do
      !config.queue_size_threshold || queues_avg_size && queues_avg_size < config.queue_size_threshold
    end

    def probes
      methods.grep(/^#{PROBE_METHOD_PREFIX}/o).map { |m| [m, send(m)] }.to_h
    end

    def alive?
      probes.values.all? { |v| v == true }
    end

    def info
      probes.merge(
        alive: alive?
      )
    end
  end
end

SidekiqStatusMonitor.start unless ENV.fetch("DISABLE_SIDEKIQ_STATUS", "")&.to_s&.gsub(/true|1/i, "true") == "true"
