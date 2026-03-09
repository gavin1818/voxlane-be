class Web::PagesController < Web::BaseController
  before_action :authenticate_web_user!, only: :account
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

  def load_account_details
    @devices = current_user.devices.order(last_seen_at: :desc, created_at: :desc)
    @latest_subscription = current_user.subscriptions
      .where(provider: BillingCustomer::PROVIDER_STRIPE)
      .order(updated_at: :desc, created_at: :desc)
      .first
  end

  def apply_checkout_flash
    case params[:checkout]
    when "success"
      flash.now[:notice] = "Payment completed. Voxlane will refresh your Pro entitlement shortly."
    when "cancelled"
      flash.now[:alert] = "Checkout was cancelled. Your current access has not changed."
    end
  end
end
