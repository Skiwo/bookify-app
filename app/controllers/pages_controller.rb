class PagesController < ApplicationController
  def landing
    return unless signed_in?

    case current_user.role
    when "shop_owner"  then redirect_to shop_dashboard_path
    when "client"      then redirect_to clients_dashboard_path
    when "freelancer"  then redirect_to freelancer_dashboard_path
    when "booker"
      if current_user.pop_configured?
        redirect_to booker_dashboard_path
      else
        redirect_to onboarding_path
      end
    end
  end

  def about
  end

  def privacy
  end
end
