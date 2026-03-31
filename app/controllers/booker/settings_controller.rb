module Booker
  class SettingsController < BaseController
    def show
    end

    def update
      if current_user.update(settings_params)
        env_label = current_user.pop_sandbox? ? "Sandbox" : "Production"
        redirect_to booker_settings_path, notice: "Settings saved. Running in #{env_label} mode."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def settings_params
      params.require(:user).permit(
        :pop_environment,
        :pop_sandbox_api_key, :pop_sandbox_hmac_secret, :pop_sandbox_partner_id,
        :pop_production_api_key, :pop_production_hmac_secret, :pop_production_partner_id
      )
    end
  end
end
