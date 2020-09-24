# frozen_string_literal: true

require "test_helper"

module Demux
  class SignalsTest < ActionDispatch::IntegrationTest
    test "sending a signal" do
      lesson = lessons(:first_lesson)

      slack_post = stub_request(:post, demux_apps(:slack).signal_url)
        .with(
          body: hash_including(
            action: "updated",
            company_id: 1,
            lesson: {
              id: lesson.id,
              name: lesson.name,
              public: lesson.public
            }
          ),
          headers: {
            "Content-Type" => "application/json",
            "User-Agent" => "Demux",
            "X-Demux-Signal" => "lesson",
            "X-Demux-Signature" => /\w.+/
          }
        )
      reporting_post = stub_request(:post, demux_apps(:reporting).signal_url)

      LessonSignal.new(lesson.id, account_id: 1).updated

      assert_requested(slack_post)
      assert_requested(reporting_post)
    end

    test "sending a signal with context" do
      lesson = lessons(:first_lesson)

      slack_post = stub_request(:post, demux_apps(:slack).signal_url)
        .with(
          body: hash_including(
            action: "destroyed",
            company_id: 1,
            lesson: {
              id: lesson.id,
              name: lesson.name,
              public: lesson.public
            }
          ),
          headers: {
            "Content-Type" => "application/json",
            "User-Agent" => "Demux",
            "X-Demux-Signal" => "lesson",
            "X-Demux-Signature" => /\w.+/
          }
        )
      reporting_post = stub_request(:post, demux_apps(:reporting).signal_url)

      LessonSignal.new(lesson, account_id: lesson.company_id).destroyed

      assert_requested(slack_post)
      assert_requested(reporting_post)
    end

    test "signal times out" do
      lesson = lessons(:first_lesson)
      slack = demux_apps(:slack)
      reporting = demux_apps(:reporting)

      slack_post = stub_request(:post, slack.signal_url)
        .with(
          body: hash_including(
            action: "updated",
            company_id: 1,
            lesson: {
              id: lesson.id,
              name: lesson.name,
              public: lesson.public
            }
          ),
          headers: {
            "Content-Type" => "application/json",
            "User-Agent" => "Demux",
            "X-Demux-Signal" => "lesson",
            "X-Demux-Signature" => /\w.+/
          }
        )
        .to_timeout # Net::OpenTimeout

      reporting_post = stub_request(:post, reporting.signal_url)
        .to_raise(Net::ReadTimeout)

      LessonSignal.new(lesson.id, account_id: lesson.company_id).updated

      assert_requested(slack_post)
      assert_requested(reporting_post)

      slack_transmission = slack.transmissions.last
      assert_equal slack_transmission.status, "request_timeout"

      reporting_transmission = reporting.transmissions.last
      assert_equal reporting_transmission.status, "request_timeout"
    end
  end
end
