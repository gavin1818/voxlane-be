class AuthIdentity < ApplicationRecord
  PROVIDER_GOOGLE = "google".freeze

  belongs_to :user

  validates :provider, presence: true
  validates :provider_uid, presence: true, uniqueness: { scope: :provider }

  before_validation :normalize_email

  scope :google, -> { where(provider: PROVIDER_GOOGLE) }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
