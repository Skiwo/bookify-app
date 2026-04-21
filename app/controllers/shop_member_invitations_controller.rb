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

    # Redirect to POP onboarding — callback will mark member as active
    redirect_to bookify_onboarding_member_path(token: @member.invitation_token)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end
end
