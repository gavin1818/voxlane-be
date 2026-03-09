class Web::RegistrationsController < Web::BaseController
  def new
    return if redirect_authenticated_user_with_pending_desktop_login!

    @user = User.new(email: params[:email].to_s.strip.downcase)
  end

  def create
    @user = User.new(registration_params)
    @user.email_verified_at = Time.current

    if @user.save
      complete_web_authentication!(@user, notice: "Your account is ready.")
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :display_name, :password, :password_confirmation)
  end
end
