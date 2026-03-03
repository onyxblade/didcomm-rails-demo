Rails.application.routes.draw do
  # Session
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Messages (admin, requires login)
  resources :messages, only: [:index, :new, :create, :show] do
    post :resend, on: :member
  end

  # Receive DIDComm messages (API, no auth)
  post "didcomm", to: "inbox#create"

  # Serve own DID Document (did:web spec)
  get ".well-known/did.json", to: "did#show"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Public feed
  root to: "public#index"
end
