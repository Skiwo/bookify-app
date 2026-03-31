class PagesController < ApplicationController
  def landing
    if signed_in?
      return redirect_to booker_dashboard_path if current_user.booker?
      return redirect_to freelancer_dashboard_path if current_user.freelancer?
    end
  end

  def about
  end

  def privacy
  end
end
