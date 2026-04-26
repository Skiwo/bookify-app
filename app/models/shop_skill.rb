class ShopSkill < ApplicationRecord
  belongs_to :shop
  belongs_to :skill

  validates :skill_id, uniqueness: { scope: :shop_id }
end
