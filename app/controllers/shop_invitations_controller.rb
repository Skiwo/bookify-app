class ShopInvitationsController < ApplicationController
  def show
    @invitation = ShopInvitation.find_by!(token: params[:token])
    @shop = @invitation.shop
  end

  def accept
    @invitation = ShopInvitation.find_by!(token: params[:token])

    if @invitation.expired?
      redirect_to shop_invitation_path(@invitation.token), alert: "This invitation has expired."
      return
    end

    if @invitation.accepted?
      redirect_to shops_path, notice: "Invitation already accepted."
      return
    end

    @invitation.accept!
    redirect_to shop_path(@invitation.shop.slug), notice: "You now have access to #{@invitation.shop.name}."
  end
end
