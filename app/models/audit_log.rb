class AuditLog < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :user, optional: true

  # action examples: "invoice.create", "invoice.update", "invoice.pdf"
  validates :action, presence: true

  def self.record!(action:, user: nil, organization: nil, target: nil, ip: nil, metadata: {})
    create!(
      action: action,
      user: user,
      organization: organization || user&.organization,
      target_type: target&.class&.name,
      target_id: target&.id,
      ip: ip,
      metadata: metadata
    )
  end
end
