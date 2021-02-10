class CreateAssignments < ActiveRecord::Migration[5.1]
  def change
    create_table :assignments do |t|
      t.integer :number

      t.timestamps
    end
  end
end
