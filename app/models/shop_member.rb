class ShopMember < ApplicationRecord
  enum :status, { invited: 0, active: 1, inactive: 2 }

  belongs_to :shop
  belongs_to :enrollment
  has_many :assigned_jobs, class_name: "Job", foreign_key: :assigned_member_id, dependent: :nullify

  delegate :name, :email, to: :enrollment

  validates :enrollment_id, uniqueness: { scope: :shop_id, message: "already a member of this shop" }

  before_create :generate_invitation_token

  private

  def generate_invitation_token
    self.invitation_token ||= SecureRandom.urlsafe_base64(32)
  end
end
