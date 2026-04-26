class Shop < ApplicationRecord
  enum :status, { draft: 0, active: 1, paused: 2, closed: 3 }
  enum :visibility, { public_shop: 0, private_shop: 1 }

  has_one_attached :avatar
  belongs_to :owner, class_name: "User"
  validates :owner_id, uniqueness: { message: "already owns a shop (one person, one shop)" }
  has_many :shop_members, dependent: :destroy
  has_many :jobs, dependent: :restrict_with_error
  has_many :shop_invitations, dependent: :destroy
  has_many :shop_skills, dependent: :destroy
  has_many :skills, through: :shop_skills

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, hyphens" }
  validates :commission_percent, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 50 }

  before_validation :generate_slug, on: :create, if: -> { slug.blank? && name.present? }

  # Accepts a String ("kokker, bartendere") or Array of slugs.
  # Finds existing Skill records by slug; ignores unknown slugs.
  def skill_slugs=(value)
    slugs = value.is_a?(String) ? value.split(",") : Array(value)
    slugs = slugs.map { |s| s.to_s.strip.downcase }.reject(&:blank?).uniq
    self.skills = Skill.where(slug: slugs)
  end

  def skill_slugs
    skills.pluck(:slug)
  end

  def active_members
    shop_members.active
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
  end
end
