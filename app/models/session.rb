class Session < ApplicationRecord
  belongs_to :user

  has_secure_token :token

  delegate :organization, :organization_id, to: :user
end
