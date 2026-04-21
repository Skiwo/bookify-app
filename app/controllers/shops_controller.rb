class ShopsController < ApplicationController
  def index
    @shops = Shop.active.public_shop.order(:name)
    @shops = @shops.where("city ILIKE ?", "%#{params[:city]}%") if params[:city].present?
    @shops = @shops.where("? = ANY(skill_tags)", params[:skill]) if params[:skill].present?
  end

  def show
    @shop = Shop.find_by!(slug: params[:slug])

    if @shop.closed?
      redirect_to shops_path, alert: "This shop is no longer available."
      return
    end

    if @shop.paused? && !existing_client_of_shop?(@shop)
      redirect_to shops_path, alert: "This shop is temporarily paused and not accepting new requests."
      return
    end

    if @shop.private_shop? && @shop.active?
      unless invited_to_shop?(@shop) || existing_client_of_shop?(@shop)
        redirect_to shops_path, alert: "This shop is private. You need an invitation to view it."
        return
      end
    end

    @members = @shop.active_members.includes(:enrollment)
  end

  private

  def invited_to_shop?(shop)
    return true if current_user&.shop_owner? && shop.owner == current_user
    email = current_user&.email || session[:guest_email]
    return false unless email
    shop.shop_invitations.pending.exists?(email: email)
  end

  def existing_client_of_shop?(shop)
    return false unless current_user&.client?
    client = Client.find_by(user: current_user)
    return false unless client
    shop.jobs.exists?(client: client)
  end
end
