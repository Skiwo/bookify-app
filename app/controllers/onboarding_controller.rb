class OnboardingController < ApplicationController
  before_action :require_authentication!

  def index
    case current_user.role
    when "shop_owner"  then redirect_to shop_dashboard_path
    when "client"      then redirect_to clients_dashboard_path
    when "freelancer"  then redirect_to freelancer_dashboard_path
    end
    # booker (default for new users) — show onboarding choice
  end
end
