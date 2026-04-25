class ProfilesController < ApplicationController
  before_action :require_authentication!
  layout :resolve_layout

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: t("flash.profile_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :avatar, :locale)
  end

  def resolve_layout
    case current_user&.role
    when "shop_owner"  then "shop"
    when "client"      then "client"
    when "freelancer"  then "freelancer"
    when "booker"      then "booker"
    else "application"
    end
  end
end
