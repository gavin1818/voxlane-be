class Subscription < ApplicationRecord
  MANAGEABLE_STATUSES = %w[trialing active past_due unpaid].freeze
  NON_ACCESS_STATUSES = %w[incomplete incomplete_expired unpaid].freeze

  belongs_to :user
  belongs_to :billing_customer

  validates :provider, :external_subscription_id, :status, presence: true
  validates :external_subscription_id, uniqueness: { scope: :provider }

  def grants_access?
    return false if status.blank?
    return false if NON_ACCESS_STATUSES.include?(status)

    current_period_end_at.nil? || current_period_end_at.future?
  end

  def cancellable?
    external_subscription_id.present? &&
      MANAGEABLE_STATUSES.include?(status) &&
      !cancel_at_period_end?
  end

  def resumable?
    external_subscription_id.present? &&
      MANAGEABLE_STATUSES.include?(status) &&
      cancel_at_period_end?
  end
end
