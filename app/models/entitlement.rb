class Entitlement < ApplicationRecord
  ACTIVE_STATUSES = %w[active trialing].freeze

  belongs_to :user

  validates :key, :status, :source, presence: true
  validates :key, uniqueness: { scope: :user_id }

  def access_granted?
    ACTIVE_STATUSES.include?(status) && (active_until.nil? || active_until.future?)
  end

  def as_api_json
    {
      key: key,
      status: status,
      source: source,
      access_granted: access_granted?,
      active_from: active_from,
      active_until: active_until,
      trial_ends_at: trial_ends_at,
      last_synced_at: last_synced_at,
      metadata: metadata
    }
  end
end
