class Web::AccountsController < Web::BaseController
  before_action :authenticate_web_user!

  def update_profile
    display_name = profile_params[:display_name].to_s.strip
    current_user.display_name = display_name.presence
    current_user.save!

    redirect_to account_path, notice: "Profile updated."
  end

  private

  def profile_params
    params.require(:profile).permit(:display_name)
  end
end
