# frozen_string_literal: true

require "test_helper"

module Demux
  class TransmissionTest < ActiveSupport::TestCase
    test "#purge removes transmissions older then the given date" do
      slack_transmission = demux_transmissions(:slack)
      purgable_transmission = demux_transmissions(:purgable_slack)

      Demux::Transmission.purge(older_than: 1.month.ago)

      assert Demux::Transmission.where(id: slack_transmission.id).exists?
      refute Demux::Transmission.where(id: purgable_transmission.id).exists?
    end
  end
end
