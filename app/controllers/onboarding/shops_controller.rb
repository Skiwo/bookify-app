module Onboarding
  class ShopsController < ApplicationController
    before_action :require_authentication!

    def new
      @shop = Shop.new(commission_percent: 5, visibility: :public_shop)
    end

    def create
      @shop = Shop.new(shop_params.merge(owner: current_user, status: :active))
      @shop.slug = generate_slug(@shop.name) if @shop.slug.blank?

      if @shop.save
        current_user.update!(role: :shop_owner)
        redirect_to shop_dashboard_path, notice: "Your shop is live! Start by inviting members or sharing your shop link."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def shop_params
      params.require(:shop).permit(:name, :slug, :description, :city, :visibility, :commission_percent, :skill_slugs, skill_slugs: [])
    end

    def generate_slug(name)
      base = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
      slug = base
      counter = 2
      while Shop.exists?(slug: slug)
        slug = "#{base}-#{counter}"
        counter += 1
      end
      slug
    end
  end
end
