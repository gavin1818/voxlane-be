class ApplicationMailer < ActionMailer::Base
  default from: -> { AppConfig.mailer_from }
  layout "mailer"
end
