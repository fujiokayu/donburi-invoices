class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.integer :invoice_seq, null: false, default: 0
      t.timestamps
    end
  end
end
