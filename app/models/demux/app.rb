require "jwt"

module Demux
  class App < ApplicationRecord
    has_many :connections
    has_secure_token :secret

    # Return an entry url with JWT payload for authorization
    #
    # @param data [Hash] data to sign and include in token payload
    # @param exp [Integer] expiration of token in seconds since the epoch
    #
    # @return [String] the entry url with signed token appended

    def signed_entry_url(data: {}, exp: 1.minute.from_now.to_i)
      "#{entry_url}?token=#{JWT.encode({ data: data, exp: exp }, secret, 'HS256')}"
    end
  end
end
