# frozen_string_literal: true

require "rack"

module SidekiqStatusMonitor
  class Server
    attr_reader :host, :port, :engine, :logger
    def initialize(host: nil, port: nil, engine: nil, logger: nil, config: nil)
      @config = config || SidekiqStatusMonitor.config
      @host = host || @config.host
      @port = port || @config.port
      @engine = engine || @config.server
      @logger = logger || @config.logger
    end

    def run!
      handler = Rack::Handler.get(@engine)
      Signal.trap("TERM") { handler.shutdown }
      handler.run(
        self,
        Port: @port,
        Host: @host,
        AccessLog: [],
        Logger: @logger
      )
    end

    def alive?
      SidekiqStatusMonitor.alive?
    end

    def payload
      SidekiqStatusMonitor.info
    end

    def call(_env)
      [
        alive? ? 200 : 500,
        {"Content-Type" => "application/json"},
        [payload.to_json]
      ]
    end
  end
end
