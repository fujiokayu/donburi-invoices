class Invoice < ApplicationRecord
  belongs_to :organization
  belongs_to :bank_account, optional: true
  has_many :invoice_lines, -> { order(:position) }, dependent: :destroy, inverse_of: :invoice

  accepts_nested_attributes_for :invoice_lines, allow_destroy: true,
                                                reject_if: ->(a) { a[:description].blank? }

  enum :status, { draft: "draft", sent: "sent", paid: "paid" }, default: "draft"

  validates :number, presence: true, uniqueness: { scope: :organization_id }
  validates :customer_name, presence: true
  validate :bank_account_belongs_to_organization

  before_validation :sync_amount_from_lines

  # amount and unit prices are stored as whole yen (JPY has no sub-unit in use).
  def total
    invoice_lines.reject(&:marked_for_destruction?)
                 .sum { |l| l.quantity.to_i * l.unit_price.to_i }
  end

  private

  def bank_account_belongs_to_organization
    return if bank_account.nil? || bank_account.organization_id == organization_id

    errors.add(:bank_account, :invalid)
  end

  # When line items are present they are the source of truth for the total.
  def sync_amount_from_lines
    self.amount = total if invoice_lines.any?
  end
end
