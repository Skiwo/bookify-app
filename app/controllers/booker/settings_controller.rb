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

    # API v2 needs only the API key (Bearer). HMAC secret / partner id were for
    # the retired connect-JWT flow and are no longer collected.
    CREDENTIAL_KEYS = %w[
      pop_sandbox_api_key
      pop_production_api_key
    ].freeze

    def settings_params
      params.require(:user).permit(
        :pop_environment,
        *CREDENTIAL_KEYS
      ).reject { |k, v| CREDENTIAL_KEYS.include?(k) && v.blank? }
    end
  end
end
