class OnboardingController < ApplicationController
  before_action :require_authentication!

  def index
    redirect_to shop_dashboard_path  if current_user.shop_owner?
    redirect_to clients_dashboard_path if current_user.client?
  end
end
