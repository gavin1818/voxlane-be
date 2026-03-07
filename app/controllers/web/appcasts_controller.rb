class Web::AppcastsController < Web::BaseController
  layout false

  def show
    unless AppConfig.sparkle_ready?
      render plain: "Sparkle release metadata is not configured.", status: :service_unavailable
      return
    end

    @published_at = AppConfig.sparkle_published_at
    @release_items = AppConfig.sparkle_release_notes_items
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
  end
end
