class Client < ApplicationRecord
  belongs_to :user, optional: true
  has_many :jobs, dependent: :restrict_with_error

  validates :org_number, presence: true, uniqueness: true,
                         format: { with: /\A\d{9}\z/, message: "must be 9 digits" }
  validates :org_name, presence: true
end
