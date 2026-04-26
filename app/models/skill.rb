class Skill < ApplicationRecord
  has_many :shop_skills, dependent: :destroy
  has_many :shops, through: :shop_skills

  validates :slug, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9-]+\z/, message: "lowercase letters, numbers, hyphens only" }

  scope :ordered, -> { order(:position, :slug) }

  def name(locale = I18n.locale)
    I18n.t("skills.#{slug}", locale: locale, default: slug.humanize)
  end

  def to_param = slug
end
