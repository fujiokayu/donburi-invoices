class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :bank_account, foreign_key: true
      t.string :number, null: false
      t.string :customer_name, null: false
      t.integer :amount_cents, null: false, default: 0
      t.string :status, null: false, default: "draft"
      t.text :notes
      t.date :due_on
      t.timestamps
    end
    # Invoice numbers are unique within a tenant, not globally.
    add_index :invoices, [:organization_id, :number], unique: true
  end
end
