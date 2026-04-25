module ShopAdmin
  class MembersController < BaseController
    def index
      @members = current_shop.shop_members.includes(:enrollment).order(created_at: :desc)
    end

    def new
      @member = current_shop.shop_members.new
    end

    def create
      enrollment = current_user.enrollments_as_booker.find_by!(id: params[:shop_member][:enrollment_id])
      @member = current_shop.shop_members.new(enrollment: enrollment, status: :invited, invited_at: Time.current)

      if @member.save
        ShopMemberMailer.invite(@member).deliver_now
        redirect_to shop_members_path, notice: t("flash.invitation_sent", email: enrollment.email)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def invite
      email = params[:email].to_s.strip.downcase
      name  = params[:name].to_s.strip.presence || email.split("@").first

      enrollment = current_user.enrollments_as_booker.find_or_initialize_by(email: email)
      enrollment.assign_attributes(name: name, status: :invited) if enrollment.new_record?

      @member = current_shop.shop_members.find_or_initialize_by(enrollment: enrollment)

      if @member.persisted?
        redirect_to shop_members_path, alert: t("flash.member_already_on_roster", email: email)
        return
      end

      @member.assign_attributes(status: :invited, invited_at: Time.current)

      if enrollment.save && @member.save
        ShopMemberMailer.invite(@member).deliver_now
        redirect_to shop_members_path, notice: t("flash.invitation_sent", email: email)
      else
        errors = (enrollment.errors.full_messages + @member.errors.full_messages).first
        redirect_to new_shop_member_path, alert: errors
      end
    end

    def resend
      @member = current_shop.shop_members.find(params[:id])
      ShopMemberMailer.invite(@member).deliver_now
      redirect_to shop_members_path, notice: t("flash.invitation_resent", email: @member.email)
    end

    def destroy
      @member = current_shop.shop_members.find(params[:id])

      if @member.enrollment.email == current_user.email
        redirect_to shop_members_path, alert: "You can't remove yourself from your own shop."
        return
      end

      @member.update!(status: :inactive)
      redirect_to shop_members_path, notice: "Member removed."
    end
  end
end
