module Freelancer
  class ProfilesController < BaseController
    def show
      @engagements = current_user.engagements_as_freelancer.active.includes(:booker)

      @profiles = @engagements.map do |engagement|
        if engagement.pop_worker_id.present? && engagement.booker.pop_configured?
          booker_client = PopApiClient.for_user(engagement.booker)
          {
            engagement: engagement,
            profile: engagement.pop_profile_data.presence,
            error: nil,
            connect_url: booker_client.connect_url(
              worker_id: engagement.pop_worker_id,
              callback_url: callbacks_manage_url
            )
          }
        else
          { engagement: engagement, profile: engagement.pop_profile_data, error: nil, connect_url: nil }
        end
      end
    end
  end
end
