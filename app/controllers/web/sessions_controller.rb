class Web::SessionsController < Web::BaseController
  def new
    redirect_to account_path if authenticated?
    @prefilled_email = params[:email].presence || current_user_email
  end

  def email
    redirect_to account_path if authenticated?
    @prefilled_email = params[:email].presence || current_user_email
  end

  def create
    email = normalized_email(session_params[:email])
    password = session_params[:password].to_s

    if email.blank? || password.blank?
      flash.now[:alert] = "Enter your email and password."
      @prefilled_email = email
      render :email, status: :unprocessable_entity
      return
    end

    user = User.find_by(email: email)
    authenticated_user = user&.authenticate(password)

    unless authenticated_user
      flash.now[:alert] = "Invalid email or password."
      @prefilled_email = email
      render :email, status: :unprocessable_entity
      return
    end

    session_authenticator.clear!
    session_authenticator.store!(authenticated_user)
    complete_web_authentication!(authenticated_user, notice: "Welcome back.")
  end

  def destroy
    reset_session
    redirect_to pricing_path, notice: "You have signed out."
  end

  private

  def session_params
    params.require(:auth).permit(:email, :password)
  end

  def normalized_email(value)
    value.to_s.strip.downcase
  end
end
