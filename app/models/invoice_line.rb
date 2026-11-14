class InvoiceLine < ApplicationRecord
  belongs_to :invoice, inverse_of: :invoice_lines

  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  def subtotal
    quantity.to_i * unit_price.to_i
  end
end
