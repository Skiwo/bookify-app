class CallbacksController < ApplicationController
  include PopProfileExtraction
  def onboard
    token = params[:token]
    worker_id = params[:worker_id]
    status = params[:status]

    unless status == "approved"
      redirect_to(root_path, alert: "Onboarding was not completed (status: #{status || 'missing'}).") and return
    end

    enrollment = Enrollment.find_by!(invitation_token: token)

    unless enrollment.invited? || enrollment.onboarding?
      redirect_to(root_path, alert: "This invitation has already been used.") and return
    end

    client = PopApiClient.for_user(enrollment.booker)
    result = client.get_profile(worker_id)

    if result.success?
      profile_data = extract_profile(result.data, worker_id)
      user = find_or_create_freelancer(profile_data, enrollment)

      ActiveRecord::Base.transaction do
        enrollment.update!(status: :onboarding) if enrollment.invited?
        enrollment.update!(
          freelancer: user,
          pop_worker_id: worker_id,
          pop_enrollment_id: profile_data["enrollment_id"],
          pop_profile_data: sanitize_profile_data(profile_data),
          status: :active,
          onboarded_at: Time.current
        )
      end

      handle_abandoned_worker(enrollment, params[:abandoned_worker_id])

      pwless_session = create_passwordless_session!(user)
      sign_in(pwless_session)
      redirect_to freelancer_dashboard_path, notice: "Welcome to Bookify! Your payout profile is set up."
    else
      enrollment.update!(status: :invited)
      redirect_to invitation_path(token: token), alert: "Onboarding failed: #{helpers.format_pop_error(result.error)}. Please try again."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid callback."
  rescue RuntimeError => e
    redirect_to root_path, alert: e.message
  end

  def manage
    worker_id = params[:worker_id]
    status = params[:status]

    unless status == "updated"
      redirect_to(root_path, alert: "Profile update was not completed (status: #{status || 'missing'}).") and return
    end

    enrollment = Enrollment.find_by!(pop_worker_id: worker_id)

    # Only the enrolled freelancer (signed in) should trigger a profile sync.
    # Without this check, anyone with a worker_id could trigger POP API calls.
    unless signed_in? && current_user == enrollment.freelancer
      redirect_to(root_path, alert: "Please sign in to complete the profile update.") and return
    end

    client = PopApiClient.for_user(enrollment.booker)
    result = client.get_profile(worker_id)
    if result.success?
      profile_data = extract_profile(result.data, worker_id)
      enrollment.update!(
        pop_profile_data: sanitize_profile_data(profile_data),
        pop_enrollment_id: profile_data["enrollment_id"] || enrollment.pop_enrollment_id
      )
    end

    handle_abandoned_worker(enrollment, params[:abandoned_worker_id])

    redirect_to freelancer_profile_path, notice: "Profile updated from POP."
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid callback."
  rescue RuntimeError => e
    redirect_to root_path, alert: e.message
  end

  private

  SENSITIVE_FIELDS = %w[personal_number date_of_birth identifier national_id ssn].freeze

  def sanitize_profile_data(data)
    return data unless data.is_a?(Hash)
    data.except(*SENSITIVE_FIELDS).transform_values do |v|
      v.is_a?(Hash) ? v.except(*SENSITIVE_FIELDS) : v
    end
  end

  # If the freelancer switched worker IDs during onboard/manage, POP sends
  # the old worker_id as abandoned_worker_id. Log it so the booker is aware.
  def handle_abandoned_worker(enrollment, abandoned_worker_id)
    return if abandoned_worker_id.blank?

    old_enrollment = Enrollment.find_by(
      booker_id: enrollment.booker_id,
      pop_worker_id: abandoned_worker_id
    )

    if old_enrollment && old_enrollment.id != enrollment.id
      Rails.logger.info("[POP] Worker ID #{abandoned_worker_id} abandoned in favor of #{enrollment.pop_worker_id} for enrollment #{enrollment.id}")
    end
  end

  def find_or_create_freelancer(profile_data, enrollment)
    email = (profile_data.dig("freelancer", "email") || profile_data["email"]).to_s.downcase.strip.presence || enrollment.email.downcase.strip
    first = profile_data.dig("freelancer", "first_name") || profile_data["first_name"]
    last = profile_data.dig("freelancer", "last_name") || profile_data["last_name"]
    name = [first, last].compact.join(" ")
    name = enrollment.name if name.blank?

    user = User.find_by(email: email)
    if user
      raise "This email (#{email}) is already registered as a booker account and cannot be used for freelancer onboarding." if user.booker?
      user.update!(name: name) if user.name.blank?
      user
    else
      User.create!(
        email: email,
        name: name,
        role: :freelancer
      )
    end
  end
end
