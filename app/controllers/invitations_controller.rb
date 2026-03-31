class InvitationsController < ApplicationController
  def show
    @enrollment = Enrollment.find_by!(invitation_token: params[:token])
    @booker = @enrollment.booker
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end

  def accept
    @enrollment = Enrollment.find_by!(invitation_token: params[:token])
    booker = @enrollment.booker

    unless booker.pop_configured?
      redirect_to(root_path, alert: "This operator hasn't connected their Payout Partner account yet. Please contact them.") and return
    end

    unless @enrollment.invited? || @enrollment.onboarding?
      redirect_to(root_path, alert: "This invitation has already been accepted.") and return
    end

    client = PopApiClient.for_user(booker)
    callback_url = callbacks_onboard_url(token: @enrollment.invitation_token)
    url = client.connect_url(
      worker_id: @enrollment.id,
      callback_url: callback_url
    )

    @enrollment.update!(status: :onboarding)
    redirect_to url, allow_other_host: true
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end
end
