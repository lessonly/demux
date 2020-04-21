Rails.application.routes.draw do
  mount Demux::Engine => "/demux"
end
