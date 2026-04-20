module JobReadable
  extend ActiveSupport::Concern

  private

  def load_read_data
    @last_read_at = current_user.job_reads.find_by(job_id: @job.id)&.last_read_at
    @job_reads = @job.job_reads.index_by(&:user_id)
    @other_participant_ids = @job.participant_user_ids - [current_user.id]
  end
end
