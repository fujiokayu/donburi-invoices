class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :bank_accounts, dependent: :destroy

  validates :name, presence: true

  # Per-tenant running number for invoice numbers (e.g. MN-2026-0001).
  # Allocated under a row lock so concurrent creates never collide.
  def next_invoice_number(prefix:, year: Date.current.year)
    with_lock do
      self.invoice_seq += 1
      save!
      format("%<prefix>s-%<year>d-%<seq>04d", prefix: prefix, year: year, seq: invoice_seq)
    end
  end
end
