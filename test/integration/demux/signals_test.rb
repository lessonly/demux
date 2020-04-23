# frozen_string_literal: true

require "test_helper"

module Demux
  class SignalsTest < ActionDispatch::IntegrationTest
    test "sending a signal" do
      lesson = lessons(:first_lesson)

      slack_post = stub_request(:post, demux_apps(:slack).signal_url)
      reporting_post = stub_request(:post, demux_apps(:reporting).signal_url)

      LessonSignal.new(lesson.id, account_id: lesson.company_id).updated

      assert_requested(slack_post)
      assert_requested(reporting_post)
    end
  end
end
