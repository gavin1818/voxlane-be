module Entitlements
  class Reconciler
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      entitlement = user.entitlements.find_or_initialize_by(key: AppConfig.entitlement_key)
      attributes = active_subscription.present? ? subscription_attributes : trial_attributes

      entitlement.assign_attributes(attributes.merge(last_synced_at: Time.current))
      entitlement.save!
      entitlement
    end

    private

    attr_reader :user

    def active_subscription
      @active_subscription ||= user.subscriptions
        .sort_by { |subscription| [subscription.current_period_end_at || Time.at(0), subscription.updated_at || Time.at(0)] }
        .reverse
        .find(&:grants_access?)
    end

    def subscription_attributes
      {
        status: active_subscription.status == "trialing" ? "trialing" : "active",
        source: active_subscription.provider,
        active_from: active_subscription.created_at || Time.current,
        active_until: active_subscription.current_period_end_at,
        trial_ends_at: active_subscription.status == "trialing" ? active_subscription.current_period_end_at : nil,
        metadata: {
          subscription_id: active_subscription.external_subscription_id,
          price_id: active_subscription.external_price_id
        }
      }
    end

    def trial_attributes
      if user.trial_ends_at.future?
        {
          status: "trialing",
          source: "account_trial",
          active_from: user.created_at,
          active_until: user.trial_ends_at,
          trial_ends_at: user.trial_ends_at,
          metadata: {
            trial_days: AppConfig.trial_days
          }
        }
      else
        {
          status: "inactive",
          source: "none",
          active_from: nil,
          active_until: user.trial_ends_at,
          trial_ends_at: user.trial_ends_at,
          metadata: {}
        }
      end
    end
  end
end
