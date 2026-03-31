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
            connect_url: booker_client.connect_url(
              worker_id: enrollment.pop_worker_id,
              callback_url: callbacks_manage_url
            )
          }
        else
          { enrollment: enrollment, profile: enrollment.pop_profile_data, error: nil, connect_url: nil }
        end
      end
    end
  end
end
