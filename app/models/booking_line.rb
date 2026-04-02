class BookingLine < ApplicationRecord
  belongs_to :booking, inverse_of: :booking_lines

  enum :booking_type, { time_based: 0, project_based: 1 }
  enum :line_type, { work: 0, benefit: 1, expense: 2, diet: 3 }

  validates :description, presence: true
  validates :rate_ore, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :hours, presence: true, numericality: { greater_than: 0 }, if: -> { time_based? && work? }
  validates :work_date, presence: true, if: -> { time_based? && work? }
  validates :total_hours, presence: true, numericality: { greater_than: 0 }, if: -> { project_based? && work? }
  validates :work_start_date, presence: true, if: -> { project_based? && work? }
  validates :work_end_date, presence: true, if: -> { project_based? && work? }

  def dependent_line?
    !work?
  end

  def rate_nok=(value)
    self.rate_ore = (value.to_f * 100).round if value.present? && value.to_f > 0
  end

  def rate_nok
    return nil unless rate_ore
    rate_ore / 100.0
  end

  def effective_hours
    project_based? ? (total_hours || 0) : (hours || 0)
  end

  def total_ore
    return 0 unless rate_ore
    (rate_ore * effective_hours).round
  end

  def total_nok
    total_ore / 100.0
  end
end
