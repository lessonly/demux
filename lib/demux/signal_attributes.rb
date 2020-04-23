# frozen_string_literal: true

module Demux
  # Attributes that are commonly used to identify a signal
  class SignalAttributes
    attr_reader :account_id, :action, :object_id, :signal_class

    class << self
      def from_object(object)
        new(
          account_id: object.account_id,
          action: object.action,
          object_id: object.object_id,
          signal_class: object.signal_class
        )
      end
    end

    def initialize(account_id:, action:, object_id:, signal_class:)
      @account_id = account_id
      @action = action
      @object_id = object_id
      @signal_class = String(signal_class)
    end

    def to_hash
      {
        account_id: @account_id,
        action: @action,
        object_id: @object_id,
        signal_class: @signal_class
      }
    end

    def hashed
      Base64.strict_encode64({
        account_id: account_id,
        action: action,
        object_id: object_id,
        signal_class: signal_class
      }.to_json)
    end
  end
end
