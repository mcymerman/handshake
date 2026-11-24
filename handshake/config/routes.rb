Rails.application.routes.draw do
  # Health check for load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"

  get "welcome" => "welcome#show"
  post "welcome" => "welcome#create"

  resource :zone, only: %i[new create destroy]
  get "here/:public_code/:token" => "zones#scan", as: :scan_zone

  resource :my_code, only: :show, controller: "my_codes"
  get "my_code/big" => "my_codes#big", as: :big_code
  resources :code_entries, only: :create
  post "demo/friend" => "demo#friend", as: :demo_friend

  resources :chat_threads, path: "chats", only: %i[index show destroy] do
    resources :messages, only: :create
    resource :add_in, only: %i[show create], controller: "add_ins"
    resource :group_handshake, only: %i[show create], controller: "group_handshakes"
    resources :proposals, only: %i[index create] do
      post :vote, on: :member
    end
    resources :people, only: %i[index update]
    resource :extension, only: :create
    resource :policy, only: :update
    resources :reports, only: %i[new create] do
      get :thanks, on: :collection
    end
    post "demo/newcomer" => "demo#newcomer", as: :demo_newcomer
  end
  get "waiting/:id" => "proposals#waiting", as: :waiting_proposal

  resource :profile, only: %i[edit update destroy]

  # Venue staff: dashboard, printable table tent and live display. The token
  # in the path is a secret and is masked in logs.
  get "dash/:token" => "venue_dashboards#show", as: :venue_dashboard
  get "dash/:token/tent" => "venue_dashboards#tent", as: :venue_tent
  get "dash/:token/live" => "venue_dashboards#live", as: :venue_live

  namespace :admin do
    root "reports#index"
    resources :reports, only: %i[index update]
    resources :venues, only: %i[index new create]
    get "metrics" => "metrics#index"
  end

  get "how" => "pages#how", as: :how
  get "privacy" => "pages#privacy", as: :privacy
  get "terms" => "pages#terms", as: :terms
end
