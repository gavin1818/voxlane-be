class Current < ActiveSupport::CurrentAttributes
  attribute :user, :auth_claims, :auth_session
end
