# Shared logic for extracting profile data from POP API responses.
#
# POP's GET /profiles/:worker_id endpoint returns a single object when the
# freelancer has one payout profile, or an array when they have multiple
# (e.g. individual salary + ENK organization). This concern normalizes
# the response to always return a single hash.
module PopProfileExtraction
  extend ActiveSupport::Concern

  private

  def extract_profile(data, worker_id)
    if data.is_a?(Array)
      data.find { |p| p["partner_worker_id"] == worker_id } || data.first || {}
    else
      data.is_a?(Hash) ? data : {}
    end
  end
end
