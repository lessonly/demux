module Demux
  class Connection < ApplicationRecord
    belongs_to :app

    # Return an entry url for this specific connection
    #
    # @return [String] the entry url with account_id in signed token

    def entry_url
      app.signed_entry_url(data: { account_id: account_id })
    end
  end
end
