class Dispute < ApplicationRecord
  enum :status, { open: 0, resolved: 1, closed: 2 }

  belongs_to :job
  belongs_to :raised_by, class_name: "User"

  validates :reason, presence: true
end
