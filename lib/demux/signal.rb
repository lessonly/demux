# frozen_string_literal: true

module Demux
  # All signals will inherit from Demux::Signal. A signal represent a message
  # to be demuxed and sent to apps.
  class Signal
    attr_reader :account_id, :context

    class << self
      attr_reader :account_type, :object_class, :signal_name

      def attributes(attr)
        @account_type = attr.fetch(:account_type)
        @object_class = attr.fetch(:object_class)
        @signal_name = attr.fetch(:signal_name)
      end
    end

    def signal_name
      self.class.signal_name
    end

    # Type of account for the give signal
    #
    # @return [String] account type
    def account_type
      self.class.account_type
    end

    def initialize(object_or_id,
                   account_id:,
                   context: {},
                   demuxer: Demux.config.default_demuxer)
      @object = nil

      initialize_object_or_id(object_or_id)

      @account_id = account_id
      @context = context.symbolize_keys
      @demuxer = demuxer
    end

    def object
      return @object if @object.present?
      return nil unless @object_id.present?

      @object = if @object_id.respond_to?(:each)
                  self.class.object_class.where(id: @object_id)
                else
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
        account_type: account_type,
        action: String(action),
        object_id: @object_id,
        context: @context.merge(context),
        signal_class: self.class.name
      ).resolve

      self
    end

    private

    def initialize_object_or_id(object_or_id)
      if object_or_id.is_a?(Integer)
        @object_id = object_or_id
      elsif object_or_id.respond_to?(:each)
        @object_id = object_or_id.each(&:to_i)
      else
        @object = object_or_id
        @object_id = object.try(:id)
      end
    end
  end
end
