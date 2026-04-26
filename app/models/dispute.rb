class Dispute < ApplicationRecord
  enum :status, { open: 0, responded: 1, resolved: 2, closed: 3 }

  belongs_to :job
  belongs_to :raised_by, class_name: "User"
  belongs_to :responded_by, class_name: "User", optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :reason, presence: true

  def respond!(user:, response:)
    raise "Cannot respond to dispute in '#{status}' state" unless open?
    update!(
      status: :responded,
      responded_by: user,
      response: response,
      responded_at: Time.current
    )
  end

  def resolve!(user:, resolution:)
    raise "Cannot resolve dispute in '#{status}' state" unless open? || responded?
    raise "Cannot resolve dispute for an already-invoiced job" if job.invoiced? || job.paid? || job.completed?
    update!(
      status: :resolved,
      resolved_by: user,
      resolution: resolution,
      resolved_at: Time.current
    )
    job.update!(status: :in_progress)
  end

  def close!(user:, resolution:)
    raise "Cannot close dispute in '#{status}' state" unless open? || responded? || resolved?
    update!(
      status: :closed,
      resolved_by: user,
      resolution: resolution,
      resolved_at: Time.current
    )
  end
end
