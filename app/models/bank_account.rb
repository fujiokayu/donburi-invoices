class BankAccount < ApplicationRecord
  belongs_to :organization
  has_many :invoices, dependent: :nullify

  validates :bank_name, :account_number, :holder_name, presence: true

  def label
    "#{bank_name} #{branch_name} #{account_type} #{account_number}"
  end
end
