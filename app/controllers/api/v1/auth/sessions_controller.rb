class Api::V1::Auth::SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def otp
    Auth::SupabaseOtpClient.request_code!(email: otp_params[:email])
    render json: { sent: true }
  end

  def verify
    render json: Auth::SupabaseOtpClient.verify_code!(
      email: verify_params[:email],
      token: verify_params[:token]
    )
  end

  def refresh
    render json: Auth::SupabaseOtpClient.refresh_session!(
      refresh_token: refresh_params[:refresh_token]
    )
  end

  private

  def otp_params
    params.require(:auth).permit(:email)
  end

  def verify_params
    params.require(:auth).permit(:email, :token)
  end

  def refresh_params
    params.require(:auth).permit(:refresh_token)
  end
end
