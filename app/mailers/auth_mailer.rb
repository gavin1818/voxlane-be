class AuthMailer < ApplicationMailer
  def password_reset(user, raw_token:)
    @user = user
    @reset_url = "#{AppConfig.frontend_url.chomp("/")}/reset-password/#{raw_token}"

    mail(
      to: user.email,
      subject: "Reset your Voxlane password"
    )
  end
end
