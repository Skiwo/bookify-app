class ShopJoinsController < ApplicationController
  def create
    @shop = Shop.find_by!(slug: params[:slug])

    unless @shop.active? && @shop.public_shop?
      redirect_to shop_path(@shop.slug), alert: "This shop is not accepting applications."
      return
    end

    email = params[:email].to_s.strip.downcase
    name  = params[:name].to_s.strip.presence || email.split("@").first

    enrollment = @shop.owner.enrollments_as_booker.find_or_initialize_by(email: email)
    enrollment.assign_attributes(name: name, status: :invited) if enrollment.new_record?

    member = @shop.shop_members.find_or_initialize_by(enrollment: enrollment)

    if member.persisted?
      redirect_to bookify_onboarding_member_path(token: member.invitation_token),
                  allow_other_host: false
      return
    end

    member.assign_attributes(status: :invited, invited_at: Time.current)

    if enrollment.save && member.save
      redirect_to bookify_onboarding_member_path(token: member.invitation_token),
                  allow_other_host: false
    else
      errors = (enrollment.errors.full_messages + member.errors.full_messages).first
      redirect_to shop_path(@shop.slug), alert: errors
    end
  end
end
