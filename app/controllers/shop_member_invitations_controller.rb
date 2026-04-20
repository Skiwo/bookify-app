class ShopMemberInvitationsController < ApplicationController
  def show
    @member = ShopMember.includes(:shop, enrollment: :freelancer).find_by!(invitation_token: params[:token])
    @shop = @member.shop
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end

  def accept
    @member = ShopMember.includes(:shop).find_by!(invitation_token: params[:token])

    unless @member.invited?
      redirect_to root_path, notice: "This invitation has already been accepted."
      return
    end

    @member.update!(status: :active, accepted_at: Time.current)
    redirect_to shop_path(@member.shop.slug),
      notice: "You've joined #{@member.shop.name}! You'll receive job assignments from the shop owner."
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end
end
