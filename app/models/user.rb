class User < ApplicationRecord
  has_secure_password validations: false

  has_one :billing_customer, -> { where(provider: BillingCustomer::PROVIDER_STRIPE) }, dependent: :destroy
  has_many :billing_customers, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :entitlements, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :auth_identities, dependent: :destroy
  has_many :auth_sessions, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy

  attr_accessor :skip_password_requirement

  validates :public_id, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :password_presence_when_required

  before_validation :ensure_public_id
  before_validation :normalize_email
  before_validation :ensure_display_name

  def trial_ends_at
    created_at + AppConfig.trial_days.days
  end

  def current_entitlement
    entitlements.find_by(key: AppConfig.entitlement_key)
  end

  def google_connected?
    auth_identities.any? { |identity| identity.provider == AuthIdentity::PROVIDER_GOOGLE }
  end

  def apple_connected?
    auth_identities.any? { |identity| identity.provider == AuthIdentity::PROVIDER_APPLE }
  end

  def password_login_enabled?
    password_digest.present?
  end

  private

  def ensure_public_id
    self.public_id = public_id.presence || SecureRandom.uuid
  end

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def ensure_display_name
    return if display_name.present?
    return if email.blank?

    self.display_name = email.split("@").first.tr("._", " ").split.map(&:capitalize).join(" ")
  end

  def password_presence_when_required
    return unless new_record?
    return if skip_password_requirement
    return if password_login_enabled?
    return if password.present?

    errors.add(:password, "must be at least 8 characters")
  end
end
