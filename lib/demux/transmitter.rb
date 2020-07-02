# frozen_string_literal: true

require "net/http"

module Demux
  # Transmits a Transmission
  class Transmitter
    # @return [TransmissionReceipt] results of the transmission attempt
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
      @request = NullRequest.new
      @response = NullResponse.new
      @timeout = Demux.config.signal_timeout
    end

    # Use the transmitter to send it's transmission
    #
    # @return [self]

    def transmit
      build_request

      send_request

      write_receipt

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
        Net::HTTP.start(@uri.hostname, @uri.port, **request_options) do |http|
          http.request(@request)
        end

      self
    rescue Net::ReadTimeout, Net::OpenTimeout, Net::WriteTimeout
      @status = :timeout
    end

    def request_options
      {
        use_ssl: @uri.scheme == "https",
        open_timeout: @timeout,
        write_timeout: @timeout,
        read_timeout: @timeout
      }
    end

    def write_receipt
      @receipt = TransmissionReceipt.new(
        request: @request,
        response: @response,
        status: status
      )
    end

    def log_transmission
      Rails.logger.debug(
        "Send #{@transmission.signal_name}/#{@transmission.action} signal \
            to #{@uri} \
            with payload #{@transmission.request_body}"
      )
    end

    def status
      @status ||= @response.is_a?(Net::HTTPSuccess) ? :success : :failure
    end
  end

  # Null object to represent having no receipt
  class NullTransmissionReceipt
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

  # Null object for missing request
  class NullRequest
    def each_header
      []
    end

    def body
      ""
    end
  end

  # Null object for missing response
  class NullResponse
    def code
      nil
    end

    def body
      ""
    end
  end

  # Returned when the Transmitter transmits
  # @see Demux::Transmitter
  class TransmissionReceipt
    attr_reader :status

    def initialize(request:, response:, status:)
      @raw_request = request
      @raw_response = response
      @status = status
    end

    # HTTP code of response
    #
    # @return [Integer, nil] http code. nil if there is no response

    def http_code
      return unless @raw_response.code

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
