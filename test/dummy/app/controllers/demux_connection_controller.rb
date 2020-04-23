class DemuxConnectionController < ApplicationController
  def show
    connection = Demux::Connection.find(params[:id])

    redirect_to connection.entry_url
  end
end
