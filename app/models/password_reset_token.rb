class PasswordResetToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :available, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for!(user)
    raw_token = Auth::TokenGenerator.call
    record = user.password_reset_tokens.create!(
      token_digest: Auth::TokenDigest.call(raw_token),
      expires_at: AppConfig.password_reset_token_ttl.from_now
    )

    [record, raw_token]
  end

  def self.find_available_by_raw_token(raw_token)
    available.find_by(token_digest: Auth::TokenDigest.call(raw_token))
  end

  def mark_used!
    update!(used_at: Time.current)
  end
end
