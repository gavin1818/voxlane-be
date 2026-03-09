class AuthSession < ApplicationRecord
  belongs_to :user

  validates :public_id, presence: true, uniqueness: true
  validates :refresh_token_digest, presence: true, uniqueness: true
  validates :auth_method, presence: true

  before_validation :ensure_public_id

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def active?
    revoked_at.blank? && expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  def ensure_public_id
    self.public_id = public_id.presence || SecureRandom.uuid
  end
end
