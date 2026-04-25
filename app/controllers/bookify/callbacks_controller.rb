module Bookify
  class CallbacksController < ApplicationController
    before_action :require_authentication!, only: [:shop_owner]

    # GET /bookify/callbacks/shop?worker_id=X&status=approved
    # shop_id from params is intentionally ignored — we look up by current_user
    # to prevent an attacker from overwriting another shop's pop_worker_id.
    def shop_owner
      unless %w[approved updated].include?(params[:status])
        redirect_to shop_dashboard_path, alert: t("flash.enrollment_failed")
        return
      end

      shop = Shop.find_by!(owner: current_user)
      shop.update!(pop_worker_id: params[:worker_id])

      owner_name = shop.owner.name.presence || shop.owner.email.split("@").first
      enrollment = shop.owner.enrollments_as_booker.find_or_initialize_by(email: shop.owner.email)
      if enrollment.new_record?
        enrollment.assign_attributes(name: owner_name, status: :invited, pop_worker_id: params[:worker_id])
        enrollment.save!
      end
      enrollment.update_columns(status: Enrollment.statuses[:active], pop_worker_id: params[:worker_id]) unless enrollment.active?

      member = shop.shop_members.find_or_initialize_by(enrollment: enrollment)
      if member.new_record?
        member.assign_attributes(status: :active, bookify_pop_worker_id: params[:worker_id],
                                 invited_at: Time.current, accepted_at: Time.current)
        member.save!
      else
        member.update_columns(status: ShopMember.statuses[:active], bookify_pop_worker_id: params[:worker_id])
      end

      redirect_to shop_dashboard_path, notice: t("flash.shop_enrolled")
    end

    # GET /bookify/callbacks/member?worker_id=X&status=approved&token=Y
    def member
      unless %w[approved updated].include?(params[:status])
        redirect_to root_path, alert: t("flash.enrollment_failed")
        return
      end

      member = ShopMember.find_by!(invitation_token: params[:token])
      member.update_columns(
        bookify_pop_worker_id: params[:worker_id],
        status: ShopMember.statuses[:active],
        accepted_at: Time.current
      )

      enrollment = member.enrollment
      enrollment.update_columns(status: Enrollment.statuses[:active]) unless enrollment.active?

      user = User.find_by(email: enrollment.email) ||
             User.create!(email: enrollment.email, name: enrollment.name, role: :freelancer)

      enrollment.update_columns(freelancer_id: user.id) if enrollment.freelancer_id.nil?

      pwless_session = create_passwordless_session!(user)
      sign_in(pwless_session)

      redirect_to freelancer_dashboard_path,
        notice: t("flash.shop_enrolled")
    end
  end
end
