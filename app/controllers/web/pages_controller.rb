class Web::PagesController < Web::BaseController
  before_action :authenticate_web_user!, only: :account
  before_action :sync_checkout_subscription, only: :account
  before_action :apply_checkout_flash, only: %i[pricing account]
  before_action :load_account_details, only: :account

  def home
  end

  def pricing
    render :plans
  end

  def download
  end

  def account
  end

  def support
  end

  def privacy
  end

  def terms
  end

  def release_notes
    @release_items = AppConfig.sparkle_release_notes_items
  end

  private

  def sync_checkout_subscription
    return unless params[:checkout] == "success" && params[:session_id].present?

    @checkout_sync_completed = Billing::StripeCheckoutCompletionSync.call(
      user: current_user,
      checkout_session_id: params[:session_id]
    ).present?

    reload_web_session! if @checkout_sync_completed
  end

  def load_account_details
    @devices = current_user.devices.order(last_seen_at: :desc, created_at: :desc)
    @latest_subscription = current_user.display_subscription(provider: BillingCustomer::PROVIDER_STRIPE)
    @desktop_checkout_handoff_url = "voxlane://billing/refresh" if params[:checkout] == "success" &&
      @latest_subscription&.grants_access? &&
      @devices.any?
  end

  def apply_checkout_flash
    case params[:checkout]
    when "success"
      flash.now[:notice] = if @checkout_sync_completed
        "Payment completed. Voxlane refreshed your Pro entitlement."
      else
        "Payment completed. Voxlane will refresh your Pro entitlement shortly."
      end
    when "cancelled"
      flash.now[:alert] = "Checkout was cancelled. Your current access has not changed."
    end
  end
end
