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

    # Called by signal to resolve transmissions.
    #
    # If you are implementing a custom demuxer, you can override this method
    # to provide your own implementation as long as you ultimately call
    # `#resolve_now` in your new implementation.
    #
    # @return [self]

    def resolve
      resolve_now

      self
    end

    # Called by the implementation of #resolve to immediately resolve
    # transmissions from a signal.
    #
    # @return [self]

    def resolve_now
      queue_transmissions

      queued_transmissions.each do |transmission|
        transmit(transmission)
      end

      self
    end

    # Called in `#resolve_now` when a resolved transmission is ready to be
    # transmitted. You can override this in a custom demuxer as long as you
    # ultimately call `#transmit` on the transmission.
    #
    # @return [self]

    def transmit(transmission)
      transmission.transmit

      self
    end

    private

    def queued_transmissions
      Transmission
        .queued
        .for_app(listening_apps)
        .where(uniqueness_hash: @signal_attributes.hashed)
    end

    def queue_transmissions
      listening_apps.transmission_requested_all(@signal_attributes)

      self
    end

    def listening_apps
      Demux::App.listening_for(
        signal_name: @signal_class.constantize.signal_name,
        account_id: @account_id
      )
    end
  end
end
