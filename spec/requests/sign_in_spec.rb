require "rails_helper"

# A confirmed magic link is the one moment Bookify knows a person came back;
# users.last_sign_in_at is how a reader tells a real sign-up from a drive-by.
RSpec.describe "Sign in", type: :request do
  it "stamps the user's last sign-in when the magic link is confirmed" do
    user = create(:user, :booker, last_sign_in_at: nil)
    session = Passwordless::Session.create!(authenticatable: user)

    get "/sign_in/#{session.identifier}/#{session.token}"

    expect(user.reload.last_sign_in_at).to be_within(5.seconds).of(Time.current)
  end
end
