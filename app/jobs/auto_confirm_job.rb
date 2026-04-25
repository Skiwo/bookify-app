class AutoConfirmJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(job_id)
    job = Job.find(job_id)

    job.with_lock do
      # Client confirmed or disputed before deadline — nothing to do
      return unless job.pending_confirmation?

      # Guard against clock skew or re-scheduled duplicates
      return unless job.confirmation_deadline_at&.past?

      result = Bookify::InvoicingService.new(job).call

      if result.success?
        Message.post_system(job, "Client did not respond within 48h — job auto-confirmed. Invoice issued by Payout Partner AS.")
        JobMailer.auto_confirmed_client(job).deliver_later
        JobMailer.job_invoiced(job).deliver_later
        JobMailer.job_invoiced_member(job).deliver_later if job.assigned_member
      else
        Rails.logger.error "[AutoConfirmJob] Failed to invoice job #{job_id}: #{result.error}"
      end
    end
  end
end
