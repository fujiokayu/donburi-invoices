class RenameMoneyColumnsToYen < ActiveRecord::Migration[8.0]
  def change
    rename_column :invoice_lines, :unit_price_cents, :unit_price
    rename_column :invoices, :amount_cents, :amount
  end
end
