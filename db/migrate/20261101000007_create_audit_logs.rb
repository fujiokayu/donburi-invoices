class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :organization, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :target_type
      t.bigint :target_id
      t.string :ip
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :audit_logs, %i[target_type target_id]
    add_index :audit_logs, :action
  end
end
