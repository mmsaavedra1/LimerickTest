class CreateAssignmentSchedules < ActiveRecord::Migration[5.1]
  def change
    create_table :assignment_schedules do |t|
      t.references :assignment, foreign_key: true
      t.integer :stage
      t.datetime :start_date, default: Time.now
      t.datetime :end_date, default: Time.now + (60*60*24*2)

      t.timestamps
    end
  end
end
