class WebhookEvent < ApplicationRecord
  validates :provider, :external_event_id, :event_type, presence: true
  validates :external_event_id, uniqueness: { scope: :provider }
end
