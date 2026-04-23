class ShopMemberMailer < ApplicationMailer
  def invite(shop_member)
    @shop_member = shop_member
    @shop = shop_member.shop
    @enrollment = shop_member.enrollment
    @invitation_url = shop_member_invitation_url(token: shop_member.invitation_token, host: Hosts::POP)
    @owner_name = @shop.owner.name.presence || @shop.name

    mail(to: @enrollment.email, subject: "#{@owner_name} invited you to join #{@shop.name} on Bookify")
  end
end
