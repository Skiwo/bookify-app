class InvitationMailer < ApplicationMailer
  def invite(enrollment)
    @enrollment = enrollment
    @booker = enrollment.booker
    @invitation_url = invitation_url(token: enrollment.invitation_token)
    sender = @booker.name.presence || "A Bookify user"
    mail(to: enrollment.email, subject: "#{sender} invited you to Bookify")
  end
end
