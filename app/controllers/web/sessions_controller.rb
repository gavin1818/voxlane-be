class Web::SessionsController < Web::BaseController
  before_action :redirect_authenticated_user!, only: %i[new email email_continue]

  def new
    @prefilled_email = params[:email].presence || current_user_email
  end

  def email
    @prefilled_email = params[:email].presence || current_user_email
    @password_step = ActiveModel::Type::Boolean.new.cast(params[:password_step])
  end

  def email_continue
    email = normalized_email(email_lookup_params[:email])

    if email.blank?
      flash.now[:alert] = "Enter your email address."
      @prefilled_email = ""
      @password_step = false
      render :email, status: :unprocessable_entity
      return
    end

    @prefilled_email = email

    if User.exists?(email: email)
      @password_step = true
      render :email
    else
      redirect_to signup_path(email: email, desktop_login: params[:desktop_login]), notice: "Create your account to continue."
    end
  end

  def create
    email = normalized_email(session_params[:email])
    password = session_params[:password].to_s

    if email.blank? || password.blank?
      flash.now[:alert] = "Enter your email and password."
      @prefilled_email = email
      @password_step = true
      render :email, status: :unprocessable_entity
      return
    end

    user = User.find_by(email: email)
    authenticated_user = user&.authenticate(password)

    unless authenticated_user
      flash.now[:alert] = "Invalid email or password."
      @prefilled_email = email
      @password_step = true
      render :email, status: :unprocessable_entity
      return
    end

    complete_web_authentication!(authenticated_user, notice: "Welcome back.", auth_method: "password")
  end

  def destroy
    @authenticated_session&.auth_session&.revoke!
    reset_session
    redirect_to pricing_path, notice: "You have signed out."
  end

  private

  def redirect_authenticated_user!
    redirect_authenticated_user_with_pending_desktop_login!
  end

  def session_params
    params.require(:auth).permit(:email, :password)
  end

  def email_lookup_params
    params.require(:auth).permit(:email)
  end

  def normalized_email(value)
    value.to_s.strip.downcase
  end
end
