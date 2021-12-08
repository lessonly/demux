# frozen_string_literal: true

require "test_helper"

module Demux
  class ConnectionTest < ActiveSupport::TestCase
    test "::listening_for returns connection based on account and signal" do
      result = Connection.listening_for(
        signal_name: "lesson",
        account_id: demux_connections(:acme_slack).account_id,
        account_type: "account"
      )

      assert result.include?(demux_connections(:acme_slack))
    end

    test "::listening_for does not return connection with a different account type" do
      result = Connection.listening_for(
        signal_name: "lesson",
        account_id: demux_connections(:acme_slack).account_id,
        account_type: "user" # acme_slack is listening for account not user
      )

      refute(
        result.include?(demux_connections(:acme_slack)),
        "acme_slack should not be in the result because it's listening for"\
        "account and not user"
      )
    end

    test "::find_by_app_indicator returns connection based on account and indicator" do
      result = Connection.find_by_app_indicator(
        indicator: "indicatio",
        account_id: demux_connections(:acme_indicatio).account_id,
        account_type: "company"
      )

      assert_equal demux_connections(:acme_indicatio), result
    end

    test "#entry_url requests a app entry url with account_id as payload" do
      connection = demux_connections(:acme_slack)
      app = demux_apps(:slack)

      url = connection.entry_url
      token = url.match(/token=(?<token>.*)/)[:token]
      decoded_token = JWT.decode(
        token, app.secret, true, algorithm: "HS256"
      )

      assert_equal(
        connection.account_id,
        decoded_token.first["data"]["account_id"]
      )
      assert_equal(
        connection.account_type,
        decoded_token.first["data"]["account_type"]
      )
    end

    test "#entry_url accepts extra data to pass along in payload" do
      connection = demux_connections(:acme_slack)
      app = demux_apps(:slack)

      url = connection.entry_url(data: { user_id: 42 })
      token = url.match(/token=(?<token>.*)/)[:token]
      decoded_token = JWT.decode(
        token, app.secret, true, algorithm: "HS256"
      )

      decoded_data = decoded_token.first["data"]

      assert_equal(
        connection.account_id,
        decoded_data["account_id"]
      )
      assert_equal 42, decoded_data["user_id"]
    end
  end
end
