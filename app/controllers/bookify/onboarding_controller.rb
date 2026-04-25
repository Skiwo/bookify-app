module Bookify
  class OnboardingController < ApplicationController
    before_action :require_authentication!, except: [:member]

    # Shop owner: redirect to POP to enroll as a freelancer (to receive commissions)
    def shop
      shop = Shop.find_by!(owner: current_user)

      if shop.pop_worker_id.present?
        redirect_to shop_dashboard_path, notice: t("flash.shop_already_enrolled")
        return
      end

      client = PopApiClient.for_bookify
      callback = bookify_callback_shop_url
      url = client.connect_url(worker_id: current_user.id, callback_url: callback)
      redirect_to url, allow_other_host: true
    end

    # Roster member: redirect to POP to enroll (to receive work payouts)
    def member
      token = params.fetch(:token)
      @member = ShopMember.find_by!(invitation_token: token)

      unless @member.invited?
        redirect_to shop_path(@member.shop.slug), notice: "Already enrolled."
        return
      end

      client = PopApiClient.for_bookify
      callback = bookify_callback_member_url(token: token)
      url = client.connect_url(worker_id: @member.id, callback_url: callback)
      @member.update!(status: :active) # optimistically mark — confirmed in callback
      redirect_to url, allow_other_host: true
    end
  end
end
