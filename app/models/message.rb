class Message < ApplicationRecord
  belongs_to :job
  belongs_to :sender, class_name: "User"

  validates :body, presence: true

  after_create_commit :broadcast_to_job

  private

  def broadcast_to_job
    ActionCable.server.broadcast("job_#{job_id}", {
      message_html: ApplicationController.renderer.render(
        partial: "shared/job_message",
        locals: { message: self }
      )
    })
  end
end
