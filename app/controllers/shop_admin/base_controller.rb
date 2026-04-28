module ShopAdmin
  class BaseController < ApplicationController
    before_action :require_authentication!
    before_action :require_shop_owner!
    before_action :shop_status_banner

    layout :resolve_layout

    helper_method :current_shop

    private

    def resolve_layout
      current_user&.freelancer? ? "freelancer" : "shop"
    end

    def require_shop_owner!
      return if performed?
      return if current_user&.shop_owner?
      # Solo shop: a freelancer owning a solo shop also has access to shop admin.
      return if current_user&.freelancer? && Shop.exists?(owner: current_user, solo: true)
      redirect_to root_path, alert: "Access denied."
    end

    def shop_status_banner
      return if current_shop.active?
      flash.now[:alert] = case current_shop.status
      when "paused" then "Your shop is paused — clients cannot submit new requests."
      when "closed" then "Your shop is closed."
      when "draft"  then "Your shop is in draft — publish it in Settings to go live."
      end
    end

    def current_shop
      @current_shop ||= Shop.find_by(owner: current_user) || redirect_to(new_onboarding_shop_path, alert: "Please set up your shop first.")
    end
  end
end
