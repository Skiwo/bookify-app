module Freelancer
  class PublicProfilesController < ApplicationController
    def show
      @freelancer = User.freelancer
                        .where(profile_public: true)
                        .includes(:freelancer_experiences, :freelancer_educations)
                        .find_by!(profile_slug: params[:slug])
      @solo_shop = Shop.find_by(owner: @freelancer, solo: true)
    end
  end
end
