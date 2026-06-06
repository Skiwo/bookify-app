module Freelancer
  class ProfilesController < BaseController
    def show
      @enrollments = current_user.enrollments_as_freelancer.active.includes(:booker)

      @profiles = @enrollments.map do |enrollment|
        if enrollment.pop_worker_id.present? && enrollment.booker.pop_configured?
          booker_client = PopApiClient.for_user(enrollment.booker)
          {
            enrollment: enrollment,
            profile: enrollment.pop_profile_data.presence,
            error: nil,
            # The code-based flow has no partner-initiated "manage" round-trip
            # (POP doesn't call back for an already-onboarded freelancer), so we
            # send them to POP to sign in and manage their profile directly.
            manage_url: "#{booker_client.app_url}/login"
          }
        else
          { enrollment: enrollment, profile: enrollment.pop_profile_data, error: nil, manage_url: nil }
        end
      end
    end
  end
end
