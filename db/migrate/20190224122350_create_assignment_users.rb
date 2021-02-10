class CreateAssignmentUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :assignment_users do |t|
      t.references :user, foreign_key: true
      t.references :assignment, foreign_key: true
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
