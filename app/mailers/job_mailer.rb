class JobMailer < ApplicationMailer
  def new_request(job)
    @job = job
    mail(to: job.shop.owner.email, subject: "New request: #{job.title}")
  end

  def quote_sent(job)
    @job = job
    mail(to: job.client.user.email, subject: "Quote received for #{job.title}")
  end

  def quote_accepted(job)
    @job = job
    mail(to: job.shop.owner.email, subject: "Quote accepted — #{job.title}")
  end

  def member_assigned(job)
    @job = job
    mail(to: job.assigned_member.enrollment.email, subject: "You've been assigned: #{job.title}")
  end

  def quote_declined(job)
    @job = job
    mail(to: job.shop.owner.email, subject: "Quote declined — #{job.title}")
  end

  def completion_requested(job)
    @job = job
    mail(to: job.client.user.email, subject: "Please confirm completion — #{job.title}")
  end

  def job_invoiced(job)
    @job = job
    mail(to: job.shop.owner.email, subject: "Invoice issued — #{job.title}")
  end

  def job_invoiced_member(job)
    @job = job
    mail(to: job.assigned_member.enrollment.email, subject: "Payment on the way — #{job.title}")
  end

  def dispute_raised(job)
    @job = job
    mail(to: job.shop.owner.email, subject: "Dispute raised — #{job.title}")
  end

  def dispute_responded(job)
    @job = job
    mail(to: job.client.user.email, subject: "Shop responded to your dispute — #{job.title}")
  end

  def dispute_resolved(job, to:)
    @job = job
    mail(to: to, subject: "Dispute resolved — #{job.title}")
  end

  def auto_confirmed_client(job)
    @job = job
    mail(to: job.client.user.email, subject: "Job auto-confirmed — #{job.title}")
  end
end
