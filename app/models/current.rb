class Current < ActiveSupport::CurrentAttributes
  attribute :user, :auth_claims
end
