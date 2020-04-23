# frozen_string_literal: true

require "jwt"

module Demux
  # Demux::App represents an external app that can be connected to an account
  # in the parent application.
  class App < ApplicationRecord
    URL_REGEX = %r{\A(http(s?)\://.+)?\z}i.freeze

    has_many :connections
    has_many :transmissions
    has_secure_token :secret

    validates :entry_url, :signal_url, format: { with: URL_REGEX }

    validates :name, presence: true

    class << self
      def listening_for(signal_name:, account_id:)
        connections = Demux::Connection.listening_for(
          signal_name: signal_name,
          account_id: account_id
        )

        joins(:connections)
          .merge(connections)
          .where.not(signal_url: nil)
      end

      def without_queued_transmissions_for(signal_hash)
        joins(
          <<~SQL
          LEFT OUTER JOIN demux_transmissions
          ON demux_transmissions.app_id = demux_apps.id
          AND demux_transmissions.status = 0
          AND demux_transmissions.uniqueness_hash = '#{signal_hash}'
          SQL
        )
          .where(demux_transmissions: { id: nil })
      end

      def transmission_requested_all(signal_attributes)
        without_queued_transmissions_for(signal_attributes.hashed).each do |app|
          app.transmission_requested(signal_attributes)
        end
      end
    end

    def transmission_requested(signal_attributes)
      transmissions.queue(signal_attributes)
    end

    # Return an entry url with JWT payload for authorization
    #
    # @param data [Hash] data to sign and include in token payload
    # @param exp [Integer] expiration of token in seconds since the epoch
    #
    # @return [String] the entry url with signed token appended

    def signed_entry_url(data: {}, exp: 1.minute.from_now.to_i)
      token = JWT.encode({ data: data, exp: exp }, secret, "HS256")
      "#{entry_url}?token=#{token}"
    end
  end
end
