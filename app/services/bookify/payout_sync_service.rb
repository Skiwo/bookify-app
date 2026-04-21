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
      true
    end
  end
end
