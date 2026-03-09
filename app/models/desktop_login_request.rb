class DesktopLoginRequest < ApplicationRecord
  belongs_to :user, optional: true

  validates :public_id, presence: true, uniqueness: true
  validates :polling_token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :ensure_public_id

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.issue!(metadata: {})
    raw_polling_token = Auth::TokenGenerator.call
    record = create!(
      polling_token_digest: Auth::TokenDigest.call(raw_polling_token),
      expires_at: AppConfig.desktop_login_ttl.from_now,
      metadata: metadata
    )

    [record, raw_polling_token]
  end

  def pending?
    !approved? && !expired?
  end

  def approved?
    approved_at.present? && user.present?
  end

  def completed?
    completed_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def valid_polling_token?(raw_polling_token)
    return false if raw_polling_token.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      polling_token_digest,
      Auth::TokenDigest.call(raw_polling_token)
    )
  end

  def approve!(approved_user)
    return self if expired?
    return self if approved? && user == approved_user

    update!(
      user: approved_user,
      approved_at: Time.current
    )

    self
  end

  private

  def ensure_public_id
    self.public_id = public_id.presence || SecureRandom.uuid
  end
end
