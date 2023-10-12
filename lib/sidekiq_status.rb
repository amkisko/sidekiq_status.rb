# frozen_string_literal: true

require "singleton"

require "sidekiq"
require "sidekiq/api"

require "sidekiq_status/version"

require "sidekiq_status/config"

require "sidekiq_status/server"
require "sidekiq_status/redis"
require "sidekiq_status/helpers"

module SidekiqStatus
  CAPSULE_NAME = "sidekiq-status"

  class << self
    def start
      Sidekiq.configure_server do |sidekiq_config|
        sidekiq_config.on(:startup) do
          logger.info("Starting SidekiqStatus #{SidekiqStatus::VERSION}")

          @server_pid = fork do
            SidekiqStatus::Server.new.run!
          end

          logger.info("SidekiqStatus started, #{config.server} pid #{@server_pid}")
        end

        sidekiq_config.on(:quiet) do
          config.shutdown_callback.call
        end

        sidekiq_config.on(:shutdown) do
          Process.kill("TERM", @server_pid) unless @server_pid.nil?
          Process.wait(@server_pid) unless @server_pid.nil?

          config.shutdown_callback.call

          logger.info("SidekiqStatus stopped")
        end
      end
    end

    def setup
      yield(config)
    end

    def redis
      @redis ||= SidekiqStatus::Redis.adapter
    end

    def logger
      config.logger || Sidekiq.logger
    end

    def config
      @config ||= SidekiqStatus::Config.instance
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

    def alive?
      [
        !config.workers_size_threshold || workers_size && workers_size >= config.workers_size_threshold,
        !config.process_set_size_threshold || process_set_size && process_set_size >= config.process_set_size_threshold,
        !config.queues_size_threshold || queues_size && queues_size >= config.queues_size_threshold,
        !config.queue_latency_threshold || queues_avg_latency && queues_avg_latency < config.queue_latency_threshold,
        !config.queue_size_threshold || queues_avg_size && queues_avg_size < config.queue_size_threshold,
        !config.custom_probe || config.custom_probe.call == true
      ].all?
    end

    def info
      {
        alive: alive?,
        workers_size: workers_size,
        process_set_size: process_set_size,
        queues_size: queues_size,
        queues_avg_latency: queues_avg_latency,
        queues_avg_size: queues_avg_size,
        custom_probe: config.custom_probe&.call == true
      }
    end
  end
end

SidekiqStatus.start unless ENV.fetch("DISABLE_SIDEKIQ_STATUS", "")&.to_s&.gsub(/true|1/i, "true") == "true"
