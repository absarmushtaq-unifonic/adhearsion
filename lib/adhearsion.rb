# encoding: utf-8

abort "ERROR: You are running Adhearsion on an unsupported version of Ruby (Ruby #{RUBY_VERSION} #{RUBY_RELEASE_DATE})! Please upgrade to at least Ruby v1.9.3, JRuby 1.7.0 or Rubinius 2.0." if RUBY_VERSION < "1.9.3"

%w(
  adhearsion/rayo
  celluloid
  active_support/inflector
).each { |r| require r }

module Adhearsion
  class << self
    delegate :client, to: Rayo::Initializer

    #
    # Sets the application path
    # @param[String|Pathname] The application path to set
    #
    def root=(path)
      Adhearsion.config[:platform].root = path.nil? ? nil : File.expand_path(path)
    end

    #
    # Returns the current application path
    # @return [Pathname] The application path
    #
    def root
      Adhearsion.config[:platform].root
    end

    def config(&block)
      @config ||= initialize_config
      block_given? and yield @config
      @config
    end

    def deprecated(new_method)
      logger.info "#{caller[0]} - This method is deprecated, please use #{new_method}."
      logger.warn caller.join("\n")
    end

    def initialize_config
      _config = Configuration.new
      env = environment.to_sym if environment.respond_to? :to_sym
      unless _config.valid_environment? env
        puts  "You tried to initialize with an invalid environment name #{env}; environment-specific config may not load successfully. Valid values are #{_config.valid_environments}."
        env = nil
      end
      _config.platform.environment = env if env
      _config
    end

    def environment
      ENV['AHN_ENV'] || :development
    end

    def environments
      config.valid_environments
    end

    def config=(config)
      @config = config
    end

    def router(&block)
      @router ||= Router.new(&block || Proc.new {})
    end

    def router=(other)
      @router = other
    end

    def active_calls
      @active_calls ||= Calls.new
    end

    def active_calls=(other)
      @active_calls = other
    end

    #
    # @return [Adhearsion::Statistics] a statistics aggregator object capable of producing stats dumps
    def statistics
      unless Celluloid::Actor[:statistics]
        Statistics.supervise_as :statistics
        Statistics.setup_event_handlers
      end
      Celluloid::Actor[:statistics]
    end

    def status
      Adhearsion::Process.state_name
    end

    def new_uuid
      SecureRandom.uuid
    end

    def new_request_id
      SecureRandom.uuid
    end

    #
    # Get a new client with a connection attached
    #
    # @param [Symbol] type the connection type (eg :XMPP, :asterisk)
    # @param [Hash] options the options to pass to the connection (credentials, etc
    #
    # @return [Adhearsion::Rayo::Client] a client object
    #
    def client_with_connection(type, options)
      connection = Rayo::Connection.const_get(type == :xmpp ? 'XMPP' : type.to_s.classify).new options
      Rayo::Client.new :connection => connection
    rescue NameError
      raise ArgumentError, "Connection type #{type.inspect} is not valid."
    end

    def execute_component(command, timeout = 60)
      client.execute_command command, :async => true
      response = command.response timeout
      raise response if response.is_a? Exception
      command
    end
  end
end

Celluloid.exception_handler { |e| Adhearsion::Events.trigger :exception, e }

module Celluloid
  class << self
    undef :logger
    def logger
      ::Logging.logger['Celluloid']
    end
  end
end

%w(
  version
  foundation
  call
  call_controller
  calls
  configuration
  console
  error
  event
  events
  generators
  initializer
  logging
  outbound_call
  plugin
  process
  protocol_error
  router
  statistics
).each { |f| require "adhearsion/#{f}" }
