class InvitationMailer < ApplicationMailer
  def invite(engagement)
    @engagement = engagement
    @booker = engagement.booker
    @invitation_url = invitation_url(token: engagement.invitation_token)
    sender = @booker.name.presence || "A Bookify user"
    mail(to: engagement.email, subject: "#{sender} invited you to Bookify")
  end
end
