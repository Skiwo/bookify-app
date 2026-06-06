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
    result = client.request_enrollment(
      worker_id: @enrollment.id,
      email: @enrollment.email,
      callback_url: callbacks_onboard_url(token: @enrollment.invitation_token)
    )

    unless result.success?
      redirect_to(root_path, alert: "Couldn't start setup with Payout Partner. Please try again.") and return
    end

    @enrollment.update!(status: :onboarding)
    # POP has emailed the freelancer a one-time code; send them to the returned
    # handoff page to enter it.
    redirect_to result.data.fetch("enroll_url"), allow_other_host: true
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end
end
