module JobReadable
  extend ActiveSupport::Concern

  private

  def load_read_data
    @last_read_at = current_user.job_reads.find_by(job_id: @job.id)&.last_read_at
    @job_reads = @job.job_reads.index_by(&:user_id)
    @other_participant_ids = @job.participant_user_ids - [current_user.id]
  end

  def load_messages
    @all_messages = @job.messages.includes(:sender, file_attachment: :blob).order(:created_at)
    if params[:all].present?
      @messages = @all_messages.to_a
      @older_count = 0
    else
      @messages = @all_messages.last(50)
      @older_count = [@all_messages.count - 50, 0].max
    end
  end
end
