class Booking < ApplicationRecord
  belongs_to :enrollment

  has_many :booking_lines, -> { order(:position) }, dependent: :destroy, inverse_of: :booking
  has_one :payout, dependent: :restrict_with_error

  accepts_nested_attributes_for :booking_lines, reject_if: :all_blank, allow_destroy: true

  enum :status, { draft: 0, completed: 1, paid: 2, cancelled: 3 }

  validates :booking_lines, presence: { message: "must have at least one line" }

  def total_ore
    booking_lines.sum(&:total_ore)
  end

  def total_nok
    total_ore / 100.0
  end

  def summary
    description.presence || booking_lines.first&.description || "Booking"
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
