class Web::AccountsController < Web::BaseController
  before_action :authenticate_web_user!

  def update_profile
    display_name = profile_params[:display_name].to_s.strip
    current_user.display_name = display_name.presence
    current_user.save!

    redirect_to account_path, notice: "Profile updated."
  end

  def update_password
    current_password = password_params[:current_password].to_s

    if current_user.password_login_enabled? && !current_user.authenticate(current_password)
      redirect_to account_path, alert: "Current password is incorrect."
      return
    end

    current_user.password = password_params[:password]
    current_user.password_confirmation = password_params[:password_confirmation]

    if current_user.save
      current_user.auth_sessions.update_all(revoked_at: Time.current, updated_at: Time.current)
      redirect_to account_path, notice: "Password updated."
    else
      redirect_to account_path, alert: current_user.errors.full_messages.to_sentence
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:display_name)
  end

  def password_params
    params.require(:password).permit(:current_password, :password, :password_confirmation)
  end
end
