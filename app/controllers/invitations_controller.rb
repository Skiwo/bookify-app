class InvitationsController < ApplicationController
  def show
    @engagement = Engagement.find_by!(invitation_token: params[:token])
    @booker = @engagement.booker
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end

  def accept
    @engagement = Engagement.find_by!(invitation_token: params[:token])
    booker = @engagement.booker

    unless booker.pop_configured?
      redirect_to(root_path, alert: "This operator hasn't connected their Payout Partner account yet. Please contact them.") and return
    end

    unless @engagement.invited? || @engagement.onboarding?
      redirect_to(root_path, alert: "This invitation has already been accepted.") and return
    end

    client = PopApiClient.for_user(booker)
    callback_url = callbacks_onboard_url(token: @engagement.invitation_token)
    url = client.connect_url(
      worker_id: @engagement.id,
      callback_url: callback_url
    )

    @engagement.update!(status: :onboarding)
    redirect_to url, allow_other_host: true
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end
end
