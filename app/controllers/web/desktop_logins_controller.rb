class Web::DesktopLoginsController < Web::BaseController
  def show
    @desktop_login_request = DesktopLoginRequest.find_by!(public_id: params[:public_id])

    if @desktop_login_request.expired?
      clear_pending_desktop_login_request!
      return
    end

    unless authenticated?
      remember_desktop_login_request!(@desktop_login_request.public_id)
      redirect_to login_path, notice: "Sign in to finish connecting the Voxlane desktop app."
      return
    end

    if @desktop_login_request.user.present? && @desktop_login_request.user != current_user
      clear_pending_desktop_login_request!
      redirect_to account_path, alert: "That desktop sign-in request belongs to another account."
      return
    end

    @desktop_login_request.approve!(current_user)
    clear_pending_desktop_login_request!
  end
end
