# frozen_string_literal: true

module Demux
  # Demux::Demuxer is the heart of pairing signals to apps.
  # It's a base implementation of what needs to happen, but apps can
  # provide their own custom demuxer that calls out to this one.
  #
  # For example a host application will likely want to process signals in a
  # background queue and can supply their own demuxer with details on how that
  # should happen.
  class Demuxer
    def initialize(signal_attributes)
      @signal_attributes = signal_attributes
      @account_id = @signal_attributes.account_id
      @signal_class = @signal_attributes.signal_class
    end

    def send_to_apps
      queue_transmissions

      queued_transmissions.each(&:transmit)

      self
    end

    def queued_transmissions
      Transmission
        .queued
        .for_app(listening_apps)
        .where(uniqueness_hash: @signal_attributes.hashed)
    end

    def listening_apps
      Demux::App.listening_for(
        signal_name: @signal_class.constantize.signal_name,
        account_id: @account_id
      )
    end

    def queue_transmissions
      listening_apps.transmission_requested_all(@signal_attributes)

      self
    end
  end
end
