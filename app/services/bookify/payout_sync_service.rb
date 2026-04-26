module Bookify
  class PayoutSyncService
    def initialize(job)
      @job = job
    end

    def call
      payout = @job.booking&.payout
      return false unless payout&.pop_payout_id

      result = PopApiClient.for_bookify.get_payout(payout.pop_payout_id)
      return false unless result.success?

      payout.update!(
        pop_status: result.data["status"],
        pop_invoice_number: result.data["invoice_number"],
        pop_response: result.data,
        synced_at: Time.current
      )
      advance_job_status!(payout.pop_status)
      true
    end

    private

    def advance_job_status!(pop_status)
      case pop_status
      when "paid", "settled"
        @job.update!(status: :paid) if @job.invoiced?
      when "completed"
        @job.update!(status: :completed) if @job.paid? || @job.invoiced?
      end
    end
  end
end
