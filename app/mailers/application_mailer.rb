class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "no-reply@mail.bookify.app")
  layout "mailer"
end
