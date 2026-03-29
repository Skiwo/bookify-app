class Engagement < ApplicationRecord
  belongs_to :booker, class_name: "User"
  belongs_to :freelancer, class_name: "User", optional: true

  has_many :bookings, dependent: :restrict_with_error

  enum :status, { invited: 0, onboarding: 1, active: 2, removed: 3 }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :booker_id }
  validates :invitation_token, uniqueness: true, allow_nil: true
  validate :valid_status_transition, if: :status_changed?
  validate :email_not_a_booker, on: :create

  before_create :generate_invitation_token
  before_validation :normalize_email

  scope :for_booker, ->(user) { where(booker: user) }
  scope :for_freelancer, ->(user) { where(freelancer: user) }

  VALID_TRANSITIONS = {
    nil => %w[invited],
    "invited" => %w[onboarding removed],
    "onboarding" => %w[active invited],
    "active" => %w[removed],
    "removed" => %w[]
  }.freeze

  def pop_synced?
    active? && pop_worker_id.present?
  end

  private

  def generate_invitation_token
    loop do
      self.invitation_token = SecureRandom.urlsafe_base64(32)
      break unless Engagement.exists?(invitation_token: invitation_token)
    end
  end

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def valid_status_transition
    return unless status_was
    allowed = VALID_TRANSITIONS.fetch(status_was, [])
    return if allowed.include?(status)
    errors.add(:status, "cannot transition from #{status_was} to #{status}")
  end

  def email_not_a_booker
    return if email.blank?
    if User.exists?(email: email.downcase.strip, role: :booker)
      errors.add(:email, "is already registered as a booker and cannot be invited as a freelancer")
    end
  end
end
