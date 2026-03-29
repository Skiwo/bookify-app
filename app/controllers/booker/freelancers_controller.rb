module Booker
  class FreelancersController < BaseController
    before_action :require_pop!, only: %i[new create resend_invite sync]

    def index
      @engagements = current_user.engagements_as_booker.order(created_at: :desc).page(params[:page])
    end

    def new
      @engagement = Engagement.new
    end

    def create
      @engagement = current_user.engagements_as_booker.build(engagement_params)
      @engagement.invited_at = Time.current

      if @engagement.save
        InvitationMailer.invite(@engagement).deliver_later
        redirect_to booker_freelancer_path(@engagement), notice: "Invitation sent to #{@engagement.email}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @engagement = current_user.engagements_as_booker.find(params[:id])
      @bookings = @engagement.bookings.order(created_at: :desc).page(params[:page]).per(20)

      if @engagement.pop_synced? && current_user.pop_configured?
        result = pop_client.get_profile(@engagement.pop_worker_id)
        @pop_profile = result.data if result.success?
        @pop_error = result.error unless result.success?
      end
    end

    def resend_invite
      @engagement = current_user.engagements_as_booker.find(params[:id])

      unless @engagement.invited? || @engagement.onboarding?
        redirect_to(booker_freelancer_path(@engagement), alert: "Can only resend for pending invitations.") and return
      end

      InvitationMailer.invite(@engagement).deliver_later
      redirect_to booker_freelancer_path(@engagement), notice: "Invitation resent to #{@engagement.email}."
    end

    def destroy
      @engagement = current_user.engagements_as_booker.find(params[:id])

      if @engagement.pop_enrollment_id.present? && current_user.pop_configured?
        pop_client.delete_enrollment(@engagement.pop_enrollment_id)
      end

      @engagement.update!(status: :removed)
      redirect_to booker_freelancers_path, notice: "Freelancer #{@engagement.name} has been removed."
    end

    def sync
      @engagement = current_user.engagements_as_booker.find(params[:id])

      if @engagement.pop_worker_id.present?
        result = pop_client.get_profile(@engagement.pop_worker_id)
        if result.success?
          @engagement.update!(pop_profile_data: result.data)
          redirect_to booker_freelancer_path(@engagement), notice: "Profile synced from POP."
        else
          redirect_to booker_freelancer_path(@engagement), alert: "Could not sync profile. Please try again."
        end
      else
        redirect_to booker_freelancer_path(@engagement), alert: "Freelancer has not completed onboarding yet."
      end
    end

    private

    def engagement_params
      params.require(:engagement).permit(:name, :email)
    end
  end
end
