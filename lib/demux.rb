# frozen_string_literal: true

require "demux/engine"
require "demux/demuxer"
require "demux/signal"
require "demux/signal_attributes"
require "demux/transmitter"

# Demux toplevel namespace
module Demux
  module_function

  class Error < StandardError; end

  # Access the current configuration

  def configuration
    @configuration ||= Configuration.new
  end

  # Alias so that we can refer to configuration as config

  def config
    configuration
  end

  # Configure the library
  #
  # @yieldparam [Demux::Configuration] current_configuration
  #
  # @example
  #   Demux.configure do |config|
  #     config.default_demuxer = "Demux::Demuxer"
  #   end
  #
  # @yieldreturn [Demux::Configuration]

  def configure
    yield configuration
  end

  # Configuration holds the current configuration for the SeisimicAPI
  # and provides defaults
  class Configuration
    # return [#resolve] (Demux::Demuxer) object called to resolve a signal
    #   to apps
    attr_accessor :default_demuxer

    # @return [Integer] (10) time in seconds before transmitter will timeout
    attr_accessor :signal_timeout

    def initialize(args = {})
      @default_demuxer = args.fetch(:default_demuxer) { Demux::Demuxer }
      @signal_timeout = args.fetch(:signal_timeout, 10)
    end
  end
end
