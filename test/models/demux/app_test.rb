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

    test "#account_type? is true for matching account types" do
      app = demux_apps(:slack)

      assert app.account_type?(:account)
    end

    test "#account_type? is false for missing account types" do
      app = demux_apps(:slack)

      refute app.account_type?("user")
    end

    test "generating a new access key" do
      app = demux_apps(:slack)
      key = app.generate_access_key

      assert_match(/BEGIN PUBLIC KEY/, key.public_key)
      assert_match(/BEGIN RSA PRIVATE KEY/, key.private_key)
      assert_match(/SHA256:/, key.fingerprint)
      assert_equal key.app_id, app.id
    end
  end
end
