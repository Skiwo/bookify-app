class User < ApplicationRecord
  enum :role, { booker: 0, freelancer: 1 }

  has_many :enrollments_as_booker, class_name: "Enrollment", foreign_key: :booker_id, dependent: :restrict_with_error, inverse_of: :booker
  has_many :enrollments_as_freelancer, class_name: "Enrollment", foreign_key: :freelancer_id, dependent: :nullify, inverse_of: :freelancer

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  before_validation :normalize_email

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
    # The REST API (Bearer api_key) is all the code-based enrollment flow needs.
    # hmac_secret / partner_id were only used to mint the deprecated bearer-JWT
    # connect link; they're retained as legacy settings but no longer required.
    active_api_key.present?
  end

  def pop_sandbox?
    pop_environment != "production"
  end

  def pop_production?
    pop_environment == "production"
  end

  def effective_pop_base_url
    return ENV["POP_BASE_URL"] if ENV["POP_BASE_URL"].present?
    # The partner REST API is served on the api.* subdomain (api-guide.md;
    # core.* serves admin/app, not /api/v2/partner/*).
    pop_sandbox? ? "https://sandbox.api.payoutpartner.com" : "https://api.payoutpartner.com"
  end

  def effective_pop_app_url
    pop_sandbox? ? "https://sandbox.app.payoutpartner.com" : "https://app.payoutpartner.com"
  end

  # API v2 needs only the API key — the HMAC secret + partner id belonged to the
  # retired connect-JWT flow and are no longer used.
  def pop_credentials
    {
      api_key: active_api_key,
      base_url: effective_pop_base_url,
      app_url: effective_pop_app_url
    }
  end

  def active_api_key
    pop_sandbox? ? pop_sandbox_api_key : pop_production_api_key
  end

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
