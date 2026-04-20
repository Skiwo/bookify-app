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
        ShopMemberMailer.invite(@member).deliver_later
        redirect_to shop_members_path, notice: "Invitation sent to #{enrollment.email}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @member = current_shop.shop_members.find(params[:id])
      @member.update!(status: :inactive)
      redirect_to shop_members_path, notice: "Member removed."
    end
  end
end
