class Shop < ApplicationRecord
  enum :status, { draft: 0, active: 1, paused: 2, closed: 3 }
  enum :visibility, { public_shop: 0, private_shop: 1 }

  has_one_attached :avatar
  belongs_to :owner, class_name: "User"
  has_many :shop_members, dependent: :destroy
  has_many :jobs, dependent: :restrict_with_error
  has_many :shop_invitations, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, hyphens" }
  validates :commission_percent, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  before_validation :generate_slug, on: :create, if: -> { slug.blank? && name.present? }

  def active_members
    shop_members.active
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
  end
end
