class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers

  rescue_from PopApiClient::PopCredentialsMissing do
    redirect_to booker_settings_path, alert: "POP credentials are missing or incomplete. Please check your settings."
  end

  before_action :refresh_session_expiry
  before_action :set_cable_cookie
  before_action :touch_online

  helper_method :current_user, :signed_in?, :pop_configured?, :pop_client, :client_registered?

  private

  def refresh_session_expiry
    session[:last_seen] = Time.current.to_i if signed_in?
  end

  def set_cable_cookie
    cookies.encrypted[:cable_user_id] = current_user&.id
  end

  def touch_online
    return unless signed_in?
    return if current_user.last_online_at && current_user.last_online_at > 1.minute.ago
    current_user.update_column(:last_online_at, Time.current)
  end

  def current_user
    @current_user ||= authenticate_by_session(User)
  end

  def signed_in?
    current_user.present?
  end

  def require_authentication!
    return if signed_in?
    save_passwordless_redirect_location!(User)
    redirect_to users_sign_in_path, alert: "Please sign in to continue."
  end

  def pop_configured?
    current_user&.pop_configured?
  end

  def require_pop!
    return if pop_configured?
    redirect_to booker_settings_path, alert: "Please configure your POP API credentials before continuing."
  end

  def pop_client
    @pop_client ||= PopApiClient.for_user(current_user)
  end

  def client_registered?
    @client_registered ||= current_user&.client? && Client.exists?(user: current_user)
  end
end
