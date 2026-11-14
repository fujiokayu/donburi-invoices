class CreateBankAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :bank_accounts do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :bank_name, null: false
      t.string :branch_name
      t.string :account_type
      t.string :account_number, null: false
      t.string :holder_name, null: false
      t.timestamps
    end
  end
end
