module ShopAdmin
  class ProfilesController < BaseController
    def show
      @shop = current_shop
    end

    def edit
      @shop = current_shop
    end

    def update
      @shop = current_shop
      if @shop.update(profile_params)
        redirect_to shop_profile_path, notice: "Profile updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:shop).permit(:name, :slug, :description, :city, :skill_tags)
    end
  end
end
