Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

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
