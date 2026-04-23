class QuoteLine < ApplicationRecord
  belongs_to :job

  validates :description, presence: true
  validates :rate_ore, numericality: { greater_than: 0 }
  validates :hours, numericality: { greater_than: 0 }
  validates :amount_ore, numericality: { greater_than: 0 }

  before_validation :calculate_amount

  private

  def calculate_amount
    self.amount_ore = (rate_ore.to_i * hours.to_f).round if rate_ore.present? && hours.present?
  end
end
