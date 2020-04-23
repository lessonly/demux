# frozen_string_literal: true

require "test_helper"

module Demux
  class AppTest < ActiveSupport::TestCase
    test "#signed_entry_url returns an entry URL with a signed token" do
      app = demux_apps(:slack)

      url = app.signed_entry_url(data: { account_id: 9 })
      token = url.match(/token=(?<token>.*)/)[:token]
      decoded_token = JWT.decode(
        token, app.secret, true, { algorithm: "HS256" }
      )

      assert_equal(9, decoded_token.first["data"]["account_id"])
      assert_match(%r{.*/connection/new\?token=.*}, url)
    end
  end
end
