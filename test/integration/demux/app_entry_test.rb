require 'test_helper'

module Demux
  class AppEntryTest < ActionDispatch::IntegrationTest
    test "a controller that redirects to an entry URL" do
      connection = demux_connections(:one)

      get "/configure_connection/#{connection.id}"
      assert_redirected_to(/\/connection\/new\?token=/)
    end
  end
end
