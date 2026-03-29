module Booker
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :require_booker!

    layout "booker"

    private

    def require_booker!
      return if performed?
      redirect_to root_path, alert: "Access denied." unless current_user&.booker?
    end
  end
end
