class User < ApplicationRecord
  enum :role, { booker: 0, freelancer: 1, client: 2, shop_owner: 3 }

  EXPERIENCE_LEVELS = %w[beginner junior experienced specialist].freeze

  has_one_attached :avatar
  has_many :enrollments_as_booker, class_name: "Enrollment", foreign_key: :booker_id, dependent: :restrict_with_error, inverse_of: :booker
  has_many :enrollments_as_freelancer, class_name: "Enrollment", foreign_key: :freelancer_id, dependent: :nullify, inverse_of: :freelancer
  has_many :job_reads, dependent: :destroy
  has_many :freelancer_experiences, dependent: :destroy
  has_many :freelancer_educations,  dependent: :destroy

  accepts_nested_attributes_for :freelancer_experiences,
    allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :freelancer_educations,
    allow_destroy: true, reject_if: :all_blank

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true
  validates :locale, inclusion: { in: %w[nb en] }
  validates :experience_level, inclusion: { in: EXPERIENCE_LEVELS }, allow_blank: true
  validates :profile_slug, uniqueness: true, allow_nil: true,
            format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers and hyphens" }

  before_validation :normalize_email
  before_save :generate_profile_slug, if: -> { profile_public? && profile_slug.blank? }

  passwordless_with :email

  def self.fetch_resource_for_passwordless(email)
    normalized = email.downcase.strip
    existing = find_by(email: normalized)
    return existing if existing

    if Enrollment.where(status: :invited).exists?(["LOWER(email) = ?", normalized])
      raise ActiveRecord::RecordNotFound, "Please use the invitation link sent to your email to get started."
    end

    create!(email: normalized, role: :booker)
  end

  def pop_configured?
    active_api_key.present? && active_hmac_secret.present? && active_partner_id.present?
  end

  def pop_sandbox?
    pop_environment != "production"
  end

  def pop_production?
    pop_environment == "production"
  end

  def effective_pop_base_url
    return ENV["POP_BASE_URL"] if ENV["POP_BASE_URL"].present?
    pop_sandbox? ? "https://sandbox.core.payoutpartner.com" : "https://core.payoutpartner.com"
  end

  def effective_pop_app_url
    pop_sandbox? ? "https://sandbox.app.payoutpartner.com" : "https://app.payoutpartner.com"
  end

  def pop_credentials
    {
      api_key: active_api_key,
      hmac_secret: active_hmac_secret,
      partner_id: active_partner_id,
      base_url: effective_pop_base_url,
      app_url: effective_pop_app_url
    }
  end

  def active_api_key
    pop_sandbox? ? pop_sandbox_api_key : pop_production_api_key
  end

  def active_hmac_secret
    pop_sandbox? ? pop_sandbox_hmac_secret : pop_production_hmac_secret
  end

  def active_partner_id
    pop_sandbox? ? pop_sandbox_partner_id : pop_production_partner_id
  end

  def experience_level_label
    I18n.t("freelancer_profile.experience_levels.#{experience_level}", default: experience_level&.humanize)
  end

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def generate_profile_slug
    base = name.to_s.downcase
                .unicode_normalize(:nfkd)
                .gsub(/[^\x00-\x7f]/, "")
                .gsub(/[^a-z0-9]+/, "-")
                .gsub(/^-|-$/, "")
                .presence || "freelancer"
    slug = base
    n = 2
    while User.where(profile_slug: slug).where.not(id: id).exists?
      slug = "#{base}-#{n}"
      n += 1
    end
    self.profile_slug = slug
  end
end
