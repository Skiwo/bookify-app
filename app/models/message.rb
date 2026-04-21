class Message < ApplicationRecord
  belongs_to :job
  belongs_to :sender, class_name: "User", optional: true

  has_one_attached :file

  validates :sender, presence: true, unless: :system_message?
  validate :body_or_file_present, unless: :system_message?
  validate :acceptable_file, if: -> { file.attached? }

  ALLOWED_TYPES = %w[image/png image/jpeg application/pdf].freeze
  MAX_FILE_SIZE = 5.megabytes

  after_create_commit :broadcast_to_job

  def self.post_system(job, body)
    create!(job: job, body: body, system_message: true)
  end

  def image_attachment?
    file.attached? && file.content_type.start_with?("image/")
  end

  def pdf_attachment?
    file.attached? && file.content_type == "application/pdf"
  end

  private

  def body_or_file_present
    errors.add(:base, "Message must have text or a file") if body.blank? && !file.attached?
  end

  def acceptable_file
    unless ALLOWED_TYPES.include?(file.content_type)
      errors.add(:file, "must be PNG, JPG, or PDF")
    end
    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "must be under 5 MB")
    end
  end

  def broadcast_to_job
    ActionCable.server.broadcast("job_#{job_id}", {
      message_html: ApplicationController.renderer.render(
        partial: "shared/job_message",
        locals: { message: self, job: job }
      )
    })
  end
end
