class FreelancerExperience < ApplicationRecord
  belongs_to :user

  validates :title,      presence: true
  validates :company,    presence: true
  validates :started_on, presence: true

  default_scope { order(:position, :started_on) }

  def current?
    ended_on.nil?
  end

  def duration_label
    finish = ended_on || Date.current
    months = ((finish.year - started_on.year) * 12 + finish.month - started_on.month)
    years  = months / 12
    rem    = months % 12
    parts  = []
    parts << "#{years} år"  if years > 0
    parts << "#{rem} mnd"   if rem > 0
    parts.join(" ")
  end
end
