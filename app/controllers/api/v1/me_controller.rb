class Api::V1::MeController < ApplicationController
  def show
    entitlement = Entitlements::Reconciler.call(current_user)

    render json: {
      user: {
        id: current_user.id,
        public_id: current_user.public_id,
        email: current_user.email,
        display_name: current_user.display_name,
        last_seen_at: current_user.last_seen_at
      },
      entitlement: entitlement.as_api_json
    }
  end
end
