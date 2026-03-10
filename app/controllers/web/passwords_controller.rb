class Web::PasswordsController < Web::BaseController
  before_action :load_password_reset_token, only: [ :edit, :update ]

  def new; end

  def create
    user = User.find_by(email: normalized_email(password_request_params[:email]))

    if user.present?
      _token_record, raw_token = PasswordResetToken.issue_for!(user)
      AuthMailer.password_reset(user, raw_token: raw_token).deliver_now
    end

    redirect_to login_path, notice: "If that email exists, we sent a password reset link."
  end

  def edit
    @raw_token = params[:token]
  end

  def update
    @password_reset_token.user.password = password_reset_params[:password]
    @password_reset_token.user.password_confirmation = password_reset_params[:password_confirmation]

    if @password_reset_token.user.save
      @password_reset_token.mark_used!
      @password_reset_token.user.auth_sessions.update_all(revoked_at: Time.current, updated_at: Time.current)
      complete_web_authentication!(
        @password_reset_token.user,
        notice: "Password reset. You are now signed in.",
        auth_method: "password"
      )
    else
      @raw_token = params[:token]
      flash.now[:alert] = @password_reset_token.user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_password_reset_token
    @password_reset_token = PasswordResetToken.find_available_by_raw_token(params[:token])
    return if @password_reset_token

    redirect_to forgot_password_path, alert: "That password reset link is invalid or expired."
  end

  def password_request_params
    params.require(:password).permit(:email)
  end

  def password_reset_params
    params.require(:password).permit(:password, :password_confirmation)
  end

  def normalized_email(value)
    value.to_s.strip.downcase
  end
end
