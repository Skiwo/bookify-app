class Job < ApplicationRecord
  enum :status, {
    draft: 0,
    quoted: 1,
    accepted: 2,
    in_progress: 3,
    pending_confirmation: 4,
    disputed: 5,
    invoiced: 6,
    paid: 7,
    completed: 8
  }

  belongs_to :shop
  belongs_to :client
  belongs_to :assigned_member, class_name: "ShopMember", optional: true
  belongs_to :booking, optional: true
  has_many :messages, dependent: :destroy
  has_many :job_reads, dependent: :destroy
  has_one :dispute, dependent: :destroy

  validates :title, presence: true

  def participant_user_ids
    ids = []
    ids << client.user_id if client&.user_id
    ids << shop.owner_id if shop&.owner_id
    ids << assigned_member.enrollment.freelancer_id if assigned_member&.enrollment&.freelancer_id
    ids.compact.uniq
  end

  def minimum_job_amount_ore
    60_000 # 600 NOK minimum
  end

  def total_amount_ore
    (work_amount_ore || 0) + (commission_amount_ore || 0)
  end

  def confirmation_expired?
    confirmation_deadline_at.present? && confirmation_deadline_at < Time.current
  end

  def quote_expired?
    quote_expires_at.present? && quote_expires_at < Time.current
  end
end
