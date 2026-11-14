class CreateAuthLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :auth_logs do |t|
      t.references :user, foreign_key: true
      t.string :event, null: false
      t.string :email
      t.string :ip
      t.string :user_agent
      t.datetime :created_at, null: false
    end
    add_index :auth_logs, :event
    add_index :auth_logs, :email
  end
end
