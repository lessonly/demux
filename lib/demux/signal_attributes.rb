# frozen_string_literal: true

module Demux
  # Attributes that are commonly used to identify a signal
  class SignalAttributes
    attr_reader :account_id,
                :account_type,
                :action,
                :context,
                :object_id,
                :signal_class

    class << self
      def from_object(object)
        new(
          account_id: object.account_id,
          account_type: object.account_type,
          action: object.action,
          context: object.context,
          object_id: object.object_id,
          signal_class: object.signal_class
        )
      end
    end

    def initialize(account_id:, account_type:, action:, context:, object_id:, signal_class:)
      @account_id = account_id
      @account_type = account_type
      @action = action
      @context = Hash(context)
      @object_id = object_id
      @signal_class = String(signal_class)
    end

    def to_hash
      {
        account_id: @account_id,
        account_type: @account_type,
        action: @action,
        context: @context,
        object_id: @object_id,
        signal_class: @signal_class
      }
    end

    # Creates a unique hash of the signal attributes to uniquely identify this
    # configuration by.
    #
    # @return [String] a sha256 hexidigest of attributes

    def hashed
      Digest::SHA256.hexdigest(to_hash.to_json)
    end
  end
end
