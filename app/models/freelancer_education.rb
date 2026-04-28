class FreelancerEducation < ApplicationRecord
  belongs_to :user

  validates :institution, presence: true

  default_scope { order(:position, graduation_year: :desc) }
end
