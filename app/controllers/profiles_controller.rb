class ProfilesController < ApplicationController
  include RoleLayout

  before_action :require_authentication!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      if @user.freelancer?
        handle_freelancer_profile_after_save
      else
        redirect_to edit_profile_path, notice: t("flash.profile_updated")
      end
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence.presence || "Could not save profile."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def handle_freelancer_profile_after_save
    if @user.profile_public?
      if @user.bookify_pop_worker_id.blank?
        # Not enrolled yet — send to POP onboarding
        redirect_to bookify_onboarding_freelancer_profile_path,
          notice: "Profil lagret! Fullfør POP-registreringen for å aktivere offentlig profil."
      else
        # Already enrolled — sync/create solo shop and stay on edit page
        Bookify::SoloShopService.sync!(@user)
        Bookify::SoloShopService.find_or_create!(@user)
        redirect_to edit_profile_path, notice: t("flash.profile_updated")
      end
    else
      redirect_to edit_profile_path, notice: t("flash.profile_updated")
    end
  end

  def profile_params
    p = params.require(:user).permit(
      :name, :avatar, :locale,
      :headline, :bio, :location, :experience_level, :profile_public,
      :hourly_rate_ore,
      :profile_skill_tags,
      freelancer_experiences_attributes: [
        :id, :title, :company, :description, :started_on, :ended_on, :position, :_destroy
      ],
      freelancer_educations_attributes: [
        :id, :institution, :degree, :field_of_study, :graduation_year, :position, :_destroy
      ]
    )
    if p[:hourly_rate_ore].present?
      p[:hourly_rate_ore] = (p[:hourly_rate_ore].to_f * 100).round
    end
    raw = p.delete(:profile_skill_tags)
    p[:profile_skill_tags] = raw.to_s.split(",").map(&:strip).reject(&:blank?) if raw
    p
  end
end
