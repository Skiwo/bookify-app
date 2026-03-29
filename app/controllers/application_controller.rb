class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers

  before_action :refresh_session_expiry

  helper_method :current_user, :signed_in?, :pop_configured?, :pop_client

  private

  def refresh_session_expiry
    session[:last_seen] = Time.current.to_i if signed_in?
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
end
