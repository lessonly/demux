Rails.application.routes.draw do
  mount Demux::Engine => "/demux"

  get "/configure_connection/:id", to: "demux_connection#show"
end
