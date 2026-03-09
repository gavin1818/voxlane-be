Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "web/pages#home"
  get "pricing", to: "web/pages#pricing", as: :pricing
  get "download", to: "web/pages#download", as: :download
  get "account", to: "web/pages#account", as: :account
  patch "account/profile", to: "web/accounts#update_profile", as: :account_profile
  patch "account/password", to: "web/accounts#update_password", as: :account_password
  get "login", to: "web/sessions#new", as: :login
  get "login/email", to: "web/sessions#email", as: :login_email
  post "login/email", to: "web/sessions#email_continue"
  post "login", to: "web/sessions#create"
  get "signup", to: "web/registrations#new", as: :signup
  post "signup", to: "web/registrations#create"
  get "forgot-password", to: "web/passwords#new", as: :forgot_password
  post "forgot-password", to: "web/passwords#create"
  get "reset-password/:token", to: "web/passwords#edit", as: :reset_password
  patch "reset-password/:token", to: "web/passwords#update"
  get "auth/google", to: "web/google_oauth#start", as: :google_auth
  get "auth/google/callback", to: "web/google_oauth#callback", as: :google_auth_callback
  get "auth/apple", to: "web/apple_oauth#start", as: :apple_auth
  match "auth/apple/callback", to: "web/apple_oauth#callback", via: %i[get post], as: :apple_auth_callback
  get "desktop-login/:public_id", to: "web/desktop_logins#show", as: :desktop_login
  get "support", to: "web/pages#support", as: :support
  get "privacy", to: "web/pages#privacy", as: :privacy
  get "terms", to: "web/pages#terms", as: :terms
  delete "logout", to: "web/sessions#destroy", as: :logout
  post "checkout", to: "web/billing#checkout", as: :checkout
  post "billing/portal", to: "web/billing#portal", as: :billing_portal
  patch "billing/subscription/cancel", to: "web/billing#cancel_subscription", as: :billing_subscription_cancel
  patch "billing/subscription/resume", to: "web/billing#resume_subscription", as: :billing_subscription_resume
  get "appcast.xml", to: "web/appcasts#show", defaults: { format: :xml }, as: :appcast
  get "releases/latest", to: "web/pages#release_notes", as: :release_notes

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :login, to: "sessions#create"
        post :refresh, to: "sessions#refresh"
        resources :desktop_sessions, only: :create, param: :public_id do
          post :poll, on: :member
        end
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
