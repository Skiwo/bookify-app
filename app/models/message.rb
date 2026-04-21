class Message < ApplicationRecord
  belongs_to :job
  belongs_to :sender, class_name: "User", optional: true

  validates :body, presence: true
  validates :sender, presence: true, unless: :system_message?

  after_create_commit :broadcast_to_job

  def self.post_system(job, body)
    create!(job: job, body: body, system_message: true)
  end

  private

  def broadcast_to_job
    ActionCable.server.broadcast("job_#{job_id}", {
      message_html: ApplicationController.renderer.render(
        partial: "shared/job_message",
        locals: { message: self, job: job }
      )
    })
  end
end
