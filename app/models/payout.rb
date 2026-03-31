class Payout < ApplicationRecord
  belongs_to :booking, inverse_of: :payout

  validates :booking_id, uniqueness: true
  validates :pop_payout_id, uniqueness: true, allow_nil: true
  validates :amount_ore, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def amount_nok
    return nil unless amount_ore
    amount_ore / 100.0
  end

  def synced?
    synced_at.present?
  end
end
