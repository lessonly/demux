# frozen_string_literal: true

module Demux
  # Demux::AccessKey represents an RSA key pair associated with an app. The
  # apps may use this key to secure communications with the parent app.
  #
  # AccessKey only stores the 'public' key for verifying communication from
  # the associated app. The 'private' key will not be stored and should be
  # provided to the app.
  #
  # The fingerprint on an AccessKey is a hashed version of the 'public' key
  # that can be used to identify a given key based on it's PEM file.
  class AccessKey < ApplicationRecord
    # The private key for a newly generated AccessKey.
    # This attribute is not persisted to the database and should be provided
    # to the external app for use.
    # @return [String] RSA private key in PEM format
    attr_accessor :private_key

    belongs_to :app

    validates :fingerprint, :public_key, presence: true

    class << self
      # Create a new access key for an app.
      # This method is intended to be used through an app record.
      # @see Demux::App#generate_access_key
      #
      # @example
      #   app = Demux::App.find(1)
      #   access_key = app.generate_access_key
      #
      #   access_key.public_key => # public key PEM
      #   access_key.private_key => # private key PEM
      #
      # @returns [Demux::AccessKey] newly created access key
      def generate_new
        key = OpenSSL::PKey::RSA.new 2048

        create(
          public_key: key.public_key.to_pem,
          fingerprint: "SHA256:#{key_fingerprint(key.public_key.to_der)}"
        ).tap do |new_key|
          new_key.private_key = key.to_pem
        end
      end

      private

      # Generate a fingerprint given the DER representation of a public key
      #
      # @param key_der [String] DER representation of a public key
      #
      # @return [String] a unique hashed representation of this public key
      def key_fingerprint(key_der)
        Base64.strict_encode64(OpenSSL::Digest.new("SHA256").digest(key_der))
      end
    end
  end
end
