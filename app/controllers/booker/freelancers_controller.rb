module Booker
  class FreelancersController < BaseController
    include PopProfileExtraction
    before_action :require_pop!, only: %i[new create resend_invite sync]

    def index
      @enrollments = current_user.enrollments_as_booker.order(created_at: :desc).page(params[:page])
    end

    def new
      @enrollment = Enrollment.new
    end

    def create
      @enrollment = current_user.enrollments_as_booker.build(enrollment_params)
      @enrollment.invited_at = Time.current

      if @enrollment.save
        InvitationMailer.invite(@enrollment).deliver_later
        redirect_to booker_freelancer_path(@enrollment), notice: "Invitation sent to #{@enrollment.email}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @enrollment = current_user.enrollments_as_booker.find(params[:id])
      @bookings = @enrollment.bookings.order(created_at: :desc).page(params[:page]).per(20)

      if @enrollment.pop_synced? && current_user.pop_configured?
        result = pop_client.get_profile(@enrollment.pop_worker_id)
        if result.success?
          @pop_profile = extract_profile(result.data, @enrollment.pop_worker_id)
        else
          @pop_error = result.error
        end
      end
    end

    def resend_invite
      @enrollment = current_user.enrollments_as_booker.find(params[:id])

      unless @enrollment.invited? || @enrollment.onboarding?
        redirect_to(booker_freelancer_path(@enrollment), alert: "Can only resend for pending invitations.") and return
      end

      InvitationMailer.invite(@enrollment).deliver_later
      redirect_to booker_freelancer_path(@enrollment), notice: "Invitation resent to #{@enrollment.email}."
    end

    def destroy
      @enrollment = current_user.enrollments_as_booker.find(params[:id])

      if @enrollment.pop_enrollment_id.present? && current_user.pop_configured?
        pop_client.delete_enrollment(@enrollment.pop_enrollment_id)
      end

      name = @enrollment.name
      @enrollment.destroy!
      redirect_to booker_freelancers_path, notice: "Freelancer #{name} has been removed."
    end

    def sync
      @enrollment = current_user.enrollments_as_booker.find(params[:id])

      if @enrollment.pop_worker_id.present?
        result = pop_client.get_profile(@enrollment.pop_worker_id)
        if result.success?
          profile_data = extract_profile(result.data, @enrollment.pop_worker_id)
          @enrollment.update!(pop_profile_data: profile_data)
          redirect_to booker_freelancer_path(@enrollment), notice: "Profile synced from POP."
        else
          redirect_to booker_freelancer_path(@enrollment), alert: "Could not sync profile: #{helpers.format_pop_error(result.error)}"
        end
      else
        redirect_to booker_freelancer_path(@enrollment), alert: "Freelancer has not completed onboarding yet."
      end
    end

    private

    def enrollment_params
      params.require(:enrollment).permit(:name, :email)
    end
  end
end
