class Web::PagesController < Web::BaseController
  before_action :authenticate_web_user!, only: :account
  before_action :apply_checkout_flash, only: %i[pricing account]

  def pricing
  end

  def account
  end

  def release_notes
    @release_items = AppConfig.sparkle_release_notes_items
  end

  private

  def apply_checkout_flash
    case params[:checkout]
    when "success"
      flash.now[:notice] = "Payment completed. Voxlane will refresh your Pro entitlement shortly."
    when "cancelled"
      flash.now[:alert] = "Checkout was cancelled. Your current access has not changed."
    end
  end
end
