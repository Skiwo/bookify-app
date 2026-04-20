module Clients
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :require_client!

    layout "client"

    helper_method :current_client

    private

    def require_client!
      return if performed?
      redirect_to root_path, alert: "Access denied." unless current_user&.client?
    end

    def current_client
      @current_client ||= ::Client.find_by!(user: current_user)
    end
  end
end
