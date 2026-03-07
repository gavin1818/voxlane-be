class BillingCustomer < ApplicationRecord
  PROVIDER_STRIPE = "stripe".freeze

  belongs_to :user

  has_many :subscriptions, dependent: :destroy

  validates :provider, presence: true
  validates :external_customer_id, presence: true, uniqueness: { scope: :provider }
end
