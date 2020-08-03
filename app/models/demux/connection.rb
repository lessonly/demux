# frozen_string_literal: true

module Demux
  class Connection < ApplicationRecord
    belongs_to :app

    class << self
      def listening_for(signal_name:, account_id:)
        where(account_id: account_id)
          .signal(signal_name)
          .or(wildcard_signal)
      end

      def signal(signal)
        where("demux_connections.signals @> ?", "{#{signal}}")
      end

      private

      def wildcard_signal
        where("demux_connections.signals @> ?", "{*}")
      end
    end

    # Return an entry url for this specific connection
    #
    # @param data [Hash] extra data to pass along when building the entry_url.
    #   Whatever is passed in this hash will be included in addition to the
    #   default `account_id` key.
    #
    # @return [String] the entry url with account ID and other data in token

    def entry_url(data: {})
      app.signed_entry_url(data: data.merge(account_id: account_id))
    end
  end
end
