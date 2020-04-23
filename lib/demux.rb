# frozen_string_literal: true

require "demux/engine"
require "demux/demuxer"
require "demux/signal"
require "demux/signal_attributes"
require "demux/transmitter"

# Demux toplevel namespace
module Demux
  # Access the current configuration

  module_function

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
    attr_accessor :default_demuxer

    def initialize(args = {})
      @default_demuxer = args.fetch(:default_demuxer) { Demux::Demuxer }
    end
  end
end
