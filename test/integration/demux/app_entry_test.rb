# frozen_string_literal: true

require "test_helper"

module Demux
  class AppEntryTest < ActionDispatch::IntegrationTest
    test "a controller that redirects to an entry URL" do
      connection = demux_connections(:acme_slack)

      get "/configure_connection/#{connection.id}"
      assert_redirected_to(%r{/connection/new\?token=})
    end
  end
end
