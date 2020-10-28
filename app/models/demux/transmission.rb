# frozen_string_literal: true

module Demux
  # Demux::Transmission represents a signal being sent to an app
  class Transmission < ApplicationRecord
    belongs_to :app

    before_save :update_uniqueness_hash

    enum status: %i[queued sending success failure request_timeout]

    class << self
      def for_app(app_relation)
        joins(:app).merge(app_relation)
      end

      def queue(signal_attributes)
        create(signal_attributes.to_hash)
      rescue ActiveRecord::RecordNotUnique
        # Unique index by status/uniqueness_hash
      end

      # Purge old transmissions
      #
      # @param older_than [String, #to_s] updated_at date before which to
      #   purge. It should be a valid datetime string or an
      #   object that returns one when to_s is called on it.
      #
      # @return [self]

      def purge(older_than:)
        where("updated_at < ?", older_than).destroy_all
      end
    end

    def transmit
      return self unless attributes_required_to_transmit_present?

      update(
        request_url: app.signal_url,
        request_body: payload.to_json,
        status: :sending
      )

      save_receipt(Transmitter.new(self).transmit.receipt)

      self
    end

    def save_receipt(receipt)
      update(
        status: receipt.status,
        response_code: receipt.http_code,
        response_body: receipt.response_body,
        request_headers: receipt.request_headers
      )
    end

    def signal_name
      signal.signal_name
    end

    def signature
      OpenSSL::HMAC.hexdigest("SHA256", app.secret, request_body)
    end

    private

    def signal_url
      app.signal_url
    end

    def payload
      @payload ||= { action: action }.merge(signal.payload_for(action))
    end

    def signal
      @signal ||= signal_class.constantize.new(
        object_id, account_id: account_id, context: context
      )
    end

    def update_uniqueness_hash
      return unless attributes_required_to_transmit_present?

      self.uniqueness_hash = SignalAttributes.from_object(self).hashed
    end

    def attributes_required_to_transmit_present?
      account_id? && action? && object_id? && signal_class?
    end
  end
end
