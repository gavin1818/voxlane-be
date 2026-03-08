Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "web/pages#home"
  get "pricing", to: "web/pages#pricing", as: :pricing
  get "account", to: "web/pages#account", as: :account
  get "login", to: "web/sessions#new", as: :login
  post "login/otp", to: "web/sessions#create_otp", as: :login_otp
  post "login/verify", to: "web/sessions#create", as: :login_verify
  delete "logout", to: "web/sessions#destroy", as: :logout
  post "checkout", to: "web/billing#checkout", as: :checkout
  post "billing/portal", to: "web/billing#portal", as: :billing_portal
  get "appcast.xml", to: "web/appcasts#show", defaults: { format: :xml }, as: :appcast
  get "releases/latest", to: "web/pages#release_notes", as: :release_notes

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :otp, to: "sessions#otp"
        post :verify, to: "sessions#verify"
        post :refresh, to: "sessions#refresh"
      end

      resource :me, only: :show, controller: "me"

      namespace :app do
        resource :entitlement, only: :show, controller: "entitlements"
        resources :devices, only: :create
      end

      namespace :billing do
        resources :checkout_sessions, only: :create
        resources :portal_sessions, only: :create
      end

      namespace :webhooks do
        post :stripe, to: "stripe#create"
      end
    end
  end
end
