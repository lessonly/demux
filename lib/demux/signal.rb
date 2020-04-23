# frozen_string_literal: true

module Demux
  # All signals will inherit from Demux::Signal. A signal represent a message
  # to be demuxed and sent to apps.
  class Signal
    attr_reader :account_id

    class << self
      attr_reader :object_class, :signal_name

      def attributes(attr)
        @object_class = attr.fetch(:object_class)
        @signal_name = attr.fetch(:signal_name)
      end
    end

    def signal_name
      self.class.signal_name
    end

    def initialize(object_id,
                   account_id:,
                   demuxer: Demux.config.default_demuxer)
      @object_id = Integer(object_id)
      @account_id = account_id
      @demuxer = demuxer
    end

    def object
      @object ||= self.class.object_class.find(@object_id)
    end

    def payload_for(action)
      if respond_to?("#{action}_payload")
        public_send("#{action}_payload")
      else
        payload
      end
    end

    def send(action)
      @demuxer.new(
        SignalAttributes.new(
          account_id: @account_id,
          action: String(action),
          object_id: @object_id,
          signal_class: self.class.name
        )
      ).send_to_apps

      self
    end
  end
end
