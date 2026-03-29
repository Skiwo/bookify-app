class Booking < ApplicationRecord
  belongs_to :engagement

  has_one :payout, dependent: :restrict_with_error

  enum :status, { draft: 0, completed: 1, paid: 2, cancelled: 3 }
  enum :booking_type, { time_based: 0, project_based: 1 }

  validates :description, presence: true
  validates :rate_ore, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :hours, presence: true, numericality: { greater_than: 0 }, if: :time_based?
  validates :work_date, presence: true, if: :time_based?
  validates :total_hours, presence: true, numericality: { greater_than: 0 }, if: :project_based?
  validates :work_start_date, presence: true, if: :project_based?
  validates :work_end_date, presence: true, if: :project_based?

  def effective_hours
    project_based? ? (total_hours || 0) : (hours || 0)
  end

  def total_ore
    return 0 unless rate_ore
    (rate_ore * effective_hours).round
  end

  def rate_nok
    return nil unless rate_ore
    rate_ore / 100.0
  end

  def total_nok
    total_ore / 100.0
  end

  def has_payout?
    payout.present?
  end

  def editable?
    draft?
  end

  def can_uncomplete?
    completed? && !has_payout?
  end
end
