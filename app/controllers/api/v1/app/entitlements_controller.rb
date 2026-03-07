class Api::V1::App::EntitlementsController < ApplicationController
  def show
    entitlement = Entitlements::Reconciler.call(current_user)

    render json: {
      entitlement: entitlement.as_api_json
    }
  end
end
