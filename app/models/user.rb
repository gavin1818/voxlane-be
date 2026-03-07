class User < ApplicationRecord
  has_one :billing_customer, -> { where(provider: BillingCustomer::PROVIDER_STRIPE) }, dependent: :destroy
  has_many :billing_customers, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :entitlements, dependent: :destroy
  has_many :devices, dependent: :destroy

  validates :supabase_uid, presence: true, uniqueness: true
  validates :email, uniqueness: { allow_nil: true }

  before_validation :normalize_email

  def trial_ends_at
    created_at + AppConfig.trial_days.days
  end

  def current_entitlement
    entitlements.find_by(key: AppConfig.entitlement_key)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
