class ProfilesController < ApplicationController
  include RoleLayout

  before_action :require_authentication!

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
end
