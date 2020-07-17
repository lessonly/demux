# frozen_string_literal: true

module Demux
  # All signals will inherit from Demux::Signal. A signal represent a message
  # to be demuxed and sent to apps.
  class Signal
    attr_reader :account_id, :context

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

    def initialize(object_or_id,
                   account_id:,
                   context: {},
                   demuxer: Demux.config.default_demuxer)
      if object_or_id.is_a?(Integer)
        @object_id = object_or_id
      else
        @object = object_or_id
        @object_id = object.try(:id)
      end
      @account_id = account_id
      @context = context.symbolize_keys
      @demuxer = demuxer
    end

    def object
      @object ||= if @object_id.present?
                    self.class.object_class.find(@object_id)
                  end
    end

    def payload_for(action)
      if respond_to?("#{action}_payload")
        public_send("#{action}_payload")
      else
        payload
      end
    end

    def send(action, context: {})
      @demuxer.new(
        account_id: @account_id,
        action: String(action),
        object_id: @object_id,
        context: @context.merge(context),
        signal_class: self.class.name
      ).resolve

      self
    end
  end
end
