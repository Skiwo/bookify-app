class ShopsController < ApplicationController
  include RoleLayout

  def index
    @shops = Shop.active.order(:name)
    @shops = @shops.where("city ILIKE ?", "%#{params[:city]}%") if params[:city].present?

    query = params[:q].presence || params[:skill].presence
    if query.present?
      pattern = "%#{query}%"
      @shops = @shops.left_joins(:skills)
                     .where("shops.name ILIKE :q OR skills.slug ILIKE :q", q: pattern)
                     .distinct
    end

    @kind = params[:kind].presence_in(%w[shops solo]) || "shops"
    @shops = @shops.where(solo: @kind == "solo")
  end

  def show
    @shop = Shop.find_by(slug: params[:slug])
    redirect_to(shops_path, alert: "Shop not found or shop owner decided to close it.") and return unless @shop

    if @shop.closed?
      redirect_to shops_path, alert: "This shop is no longer available."
      return
    end

    if @shop.paused? && !existing_client_of_shop?(@shop)
      redirect_to shops_path, alert: "This shop is temporarily paused and not accepting new requests."
      return
    end

    @members = @shop.active_members.includes(:enrollment)
  end

  private

  def existing_client_of_shop?(shop)
    return false unless current_user&.client?
    client = Client.find_by(user: current_user)
    return false unless client
    shop.jobs.exists?(client: client)
  end
end
