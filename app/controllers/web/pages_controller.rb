class Web::PagesController < Web::BaseController
  before_action :authenticate_web_user!, only: :account
  before_action :sync_checkout_subscription, only: :account
  before_action :apply_checkout_flash, only: %i[pricing account]
  before_action :load_account_details, only: :account
  before_action :load_install_instructions, only: :install_instructions

  def home
  end

  def pricing
    render :plans
  end

  def download
  end

  def install_instructions
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

  def load_install_instructions
    @download_link = sanitized_download_link(params[:downloadLink])
    @download_filename = download_filename(@download_link)
    @download_package_label = download_package_label(@download_filename)
    @install_steps = install_steps_for(@download_filename)
  end

  def sanitized_download_link(candidate)
    fallback = AppConfig.sparkle_download_url
    return fallback if candidate.blank?

    download_uri = URI.parse(candidate)
    return fallback unless download_uri.is_a?(URI::HTTP) || download_uri.is_a?(URI::HTTPS)

    allowed_uris = [AppConfig.app_download_url, AppConfig.sparkle_download_url].filter_map do |url|
      URI.parse(url)
    rescue URI::InvalidURIError
      nil
    end

    return fallback if allowed_uris.none? { |allowed_uri| same_origin?(download_uri, allowed_uri) }

    candidate
  rescue URI::InvalidURIError
    fallback
  end

  def same_origin?(left, right)
    left.scheme == right.scheme && left.host == right.host && left.port == right.port
  end

  def download_filename(download_link)
    path = URI.parse(download_link).path.to_s
    filename = URI::DEFAULT_PARSER.unescape(File.basename(path))
    filename.presence || "#{AppConfig.app_name}.zip"
  rescue URI::InvalidURIError
    "#{AppConfig.app_name}.zip"
  end

  def download_package_label(filename)
    case File.extname(filename).downcase
    when ".dmg"
      "disk image"
    when ".pkg"
      "installer package"
    when ".zip"
      "zip archive"
    else
      "installer file"
    end
  end

  def install_steps_for(filename)
    app_bundle = "#{AppConfig.app_name}.app"

    case File.extname(filename).downcase
    when ".pkg"
      [
        {
          number: 1,
          title: "Run the installer",
          copy: "Open #{filename} from your Downloads folder and continue through the installer prompts.",
          visual: :downloads
        },
        {
          number: 2,
          title: "Keep the default install location",
          copy: "Let macOS place #{AppConfig.app_name} in Applications so it is available system-wide.",
          visual: :install
        },
        {
          number: 3,
          title: "Launch #{AppConfig.app_name}",
          copy: "Open #{AppConfig.app_name} from Applications. If macOS asks for confirmation, choose Open to finish setup.",
          visual: :launch
        }
      ]
    else
      [
        {
          number: 1,
          title: "Open the download",
          copy: "Open #{filename} from your Downloads folder so macOS can prepare #{app_bundle}.",
          visual: :downloads
        },
        {
          number: 2,
          title: "Move it to Applications",
          copy: "Drag #{app_bundle} into your Applications folder so future updates stay in one place.",
          visual: :install
        },
        {
          number: 3,
          title: "Launch #{AppConfig.app_name}",
          copy: "Open #{AppConfig.app_name} from Applications. If macOS asks for confirmation, choose Open to finish setup.",
          visual: :launch
        }
      ]
    end
  end

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
