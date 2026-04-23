class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "no-reply@mail.bookify.app")
  layout "mailer"

  before_action :set_host_vars

  private

  def set_host_vars
    @bookify_host = Hosts::BOOKIFY
    @pop_host     = Hosts::POP
  end
end
