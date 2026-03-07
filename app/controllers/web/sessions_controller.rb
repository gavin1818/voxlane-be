class Web::SessionsController < Web::BaseController
  def new
    redirect_to account_path if authenticated?
    @prefilled_email = session[:pending_login_email].presence || current_user_email
  end

  def create_otp
    email = normalized_email(otp_params[:email])

    if email.blank?
      redirect_to login_path, alert: "Enter your email to receive a sign-in code."
      return
    end

    Auth::SupabaseOtpClient.request_code!(email: email)
    session[:pending_login_email] = email
    redirect_to login_path, notice: "We sent a 6-digit code to #{email}."
  end

  def create
    email = normalized_email(verify_params[:email].presence || session[:pending_login_email])
    token = verify_params[:token].to_s.strip

    if email.blank? || token.blank?
      redirect_to login_path, alert: "Enter the email and the 6-digit code from your inbox."
      return
    end

    response = Auth::SupabaseOtpClient.verify_code!(email: email, token: token)
    session_authenticator.clear!
    session_authenticator.store!(response)
    session.delete(:pending_login_email)

    redirect_after_sign_in(default: account_path)
  end

  def destroy
    reset_session
    redirect_to pricing_path, notice: "You have signed out."
  end

  private

  def otp_params
    params.require(:auth).permit(:email)
  end

  def verify_params
    params.require(:auth).permit(:email, :token)
  end

  def normalized_email(value)
    value.to_s.strip.downcase
  end
end
