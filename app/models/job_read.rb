class JobRead < ApplicationRecord
  belongs_to :job
  belongs_to :user

  validates :last_read_at, presence: true
  validates :user_id, uniqueness: { scope: :job_id }
end
