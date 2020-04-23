# frozen_string_literal: true

require "net/http"

module Demux
  # Transmit a Transmission
  class Transmitter
    attr_reader :receipt
    # Constructor
    #
    # @param transmission [Demux::Transmission] the transmission to be sent
    #
    # @return [self] the initialized Demux::Transmitter

    def initialize(transmission)
      @transmission = transmission
      @uri = URI(@transmission.request_url)
      @receipt = NullTransmissionReceipt.new
    end

    # Use the transmitter to send it's transmission
    #
    # @return [self]

    def transmit
      build_request

      send_request

      @receipt = TransmissionReceipt.new(@request, @response)

      log_transmission

      self
    end

    private

    def build_request
      @request = Net::HTTP::Post.new(@uri).tap do |request|
        request["X-Demux-Signal"] = @transmission.signal_name
        request["X-Demux-Signature"] = @transmission.signature
        request["Content-Type"] = "application/json"
        request["User-Agent"] = "Demux"
        request.body = @transmission.request_body
      end
    end

    def send_request
      @response =
        Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: true) do |http|
          http.request(@request)
        end
    end

    def log_transmission
      Rails.logger.debug(
        "Send #{@transmission.signal_name}/#{@transmission.action} signal \
            to #{@uri} \
            with payload #{@transmission.request_body}"
      )
    end
  end

  # Null object to represent having no receipt
  class NullTransmissionReceipt
    def success?
      nil
    end

    def http_code
      nil
    end

    def request_headers
      {}
    end

    def request_body
      ""
    end

    def response_body
      ""
    end
  end

  # Returned when the Transmitter transmits
  # @see Demux::Transmitter
  class TransmissionReceipt
    def initialize(request, response)
      @raw_request = request
      @raw_response = response
    end

    # Was the response code 2xx
    #
    # @return [Boolean]

    def success?
      @raw_response.is_a?(Net::HTTPSuccess)
    end

    # HTTP code of response
    #
    # @return [Integer] http code

    def http_code
      Integer(@raw_response.code)
    end

    # Headers that were sent with request
    #
    # @return [Hash] Hash of headers

    def request_headers
      @raw_request.each_header.to_h
    end

    # Body of the request
    #
    # @return [String] request body

    def request_body
      @raw_request.body
    end

    # Body of the response
    #
    # @return [String] response body

    def response_body
      @raw_response.body
    end
  end
end
