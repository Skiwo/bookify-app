class CallbacksController < ApplicationController
  def onboard
    token = params[:token]
    worker_id = params[:worker_id]

    engagement = Engagement.find_by!(invitation_token: token)

    unless engagement.invited? || engagement.onboarding?
      redirect_to(root_path, alert: "This invitation has already been used.") and return
    end

    client = PopApiClient.for_user(engagement.booker)
    result = client.get_profile(worker_id)

    if result.success?
      profile_data = result.data
      user = find_or_create_freelancer(profile_data, engagement)

      ActiveRecord::Base.transaction do
        engagement.update!(
          freelancer: user,
          pop_worker_id: worker_id,
          pop_profile_data: sanitize_profile_data(profile_data),
          status: :active,
          onboarded_at: Time.current
        )
      end

      pwless_session = create_passwordless_session!(user)
      sign_in(pwless_session)
      redirect_to freelancer_dashboard_path, notice: "Welcome to Bookify! Your payout profile is set up."
    else
      engagement.update!(status: :invited)
      redirect_to invitation_path(token: token), alert: "Something went wrong during onboarding. Please try again."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid callback."
  rescue RuntimeError => e
    redirect_to root_path, alert: e.message
  end

  def manage
    worker_id = params[:worker_id]
    engagement = Engagement.find_by!(pop_worker_id: worker_id)

    client = PopApiClient.for_user(engagement.booker)
    result = client.get_profile(worker_id)
    if result.success?
      engagement.update!(pop_profile_data: sanitize_profile_data(result.data))
    end

    if engagement.freelancer && current_user == engagement.freelancer
      redirect_to freelancer_profile_path, notice: "Profile updated from POP."
    else
      redirect_to root_path
    end
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

  def find_or_create_freelancer(profile_data, engagement)
    email = engagement.email.downcase.strip
    name = [profile_data.dig("first_name"), profile_data.dig("last_name")].compact.join(" ")
    name = engagement.name if name.blank?

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
