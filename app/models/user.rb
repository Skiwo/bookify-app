class User < ApplicationRecord
  enum :role, { booker: 0, freelancer: 1 }

  has_many :engagements_as_booker, class_name: "Engagement", foreign_key: :booker_id, dependent: :restrict_with_error, inverse_of: :booker
  has_many :engagements_as_freelancer, class_name: "Engagement", foreign_key: :freelancer_id, dependent: :nullify, inverse_of: :freelancer

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  before_validation :normalize_email

  passwordless_with :email

  def self.fetch_resource_for_passwordless(email)
    normalized = email.downcase.strip
    existing = find_by(email: normalized)
    return existing if existing

    if Engagement.where(status: :invited).exists?(["LOWER(email) = ?", normalized])
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

  def pop_credentials
    {
      api_key: active_api_key,
      hmac_secret: active_hmac_secret,
      partner_id: active_partner_id,
      base_url: effective_pop_base_url
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

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
