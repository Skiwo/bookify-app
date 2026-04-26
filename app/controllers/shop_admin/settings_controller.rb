module ShopAdmin
  class SettingsController < BaseController
    def show
      @shop = current_shop
    end

    def update
      @shop = current_shop
      if @shop.update(shop_params)
        redirect_to shop_settings_path, notice: t("flash.settings_updated")
      else
        render :show, status: :unprocessable_entity
      end
    end

    def pause
      current_shop.paused!
      redirect_to shop_settings_path, notice: t("flash.shop_paused")
    end

    def close
      current_shop.closed!
      redirect_to shop_settings_path, notice: t("flash.shop_closed")
    end

    def reopen
      current_shop.active!
      redirect_to shop_settings_path, notice: t("flash.shop_active")
    end

    private

    def shop_params
      params.require(:shop).permit(:name, :description, :city, :visibility, :commission_percent, :pop_worker_id, :avatar, :skill_slugs, skill_slugs: [])
    end
  end
end
