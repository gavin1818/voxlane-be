class Api::V1::MeController < ApplicationController
  def show
    entitlement = Entitlements::Reconciler.call(current_user)

    render json: {
      user: {
        id: current_user.id,
        supabase_uid: current_user.supabase_uid,
        email: current_user.email,
        display_name: current_user.display_name,
        last_seen_at: current_user.last_seen_at
      },
      entitlement: entitlement.as_api_json
    }
  end
end
