class AuthLog < ApplicationRecord
  belongs_to :user, optional: true

  # event examples: "login.success", "login.failure", "logout"
  validates :event, presence: true

  def self.record!(event:, email:, user: nil, ip: nil, user_agent: nil)
    create!(event: event, email: email, user: user, ip: ip, user_agent: user_agent)
  end
end
