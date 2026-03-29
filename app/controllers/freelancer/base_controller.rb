module Freelancer
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :require_freelancer!

    layout "freelancer"

    private

    def require_freelancer!
      return if performed?
      redirect_to root_path, alert: "Access denied." unless current_user&.freelancer?
    end
  end
end
