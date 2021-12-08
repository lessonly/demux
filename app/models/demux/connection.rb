# frozen_string_literal: true

module Demux
  # Connection between an account and a Demux::App
  class Connection < ApplicationRecord
    belongs_to :app

    class << self
      # Retrieve connections listening for a specific signal and account
      #
      # @param signal_name [String] name of the signal
      # @param account_id [Integer] ID of the account
      # @param account_type [String] Type of account for the supplied ID
      #
      # @return [ActiveRecord::Relation<Demux::Connection>]
      def listening_for(signal_name:, account_id:, account_type:)
        where(
          account_id: account_id,
          account_type: account_type
        )
          .signal(signal_name)
          .or(wildcard_signal)
      end

      # Find connections listening for a specific signal name
      #
      # @param signal [String] name of the signal
      #
      # @return [ActiveRecord::Relation<Demux::Connection>]
      def signal(signal)
        where("demux_connections.signals @> ?", "{#{signal}}")
      end

      # Find connections that belong to an app with a specific indicator
      #
      # @param indicator [String] name of the indicator
      #
      # @return [ActiveRecord::Relation<Demux::Connection>]
      def find_by_app_indicator(indicator:, account_id:, account_type:)
        find_by(
          app: Demux::App.where(indicator: indicator),
          account_id: account_id,
          account_type: account_type
        )
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
    #   default `account_id` and `account_type` keys.
    #
    # @return [String] the entry url with account ID, account type, and other
    #   data in token
    def entry_url(data: {})
      app.signed_entry_url(
        data: data.merge(
          account_id: account_id, account_type: account_type
        )
      )
    end
  end
end
