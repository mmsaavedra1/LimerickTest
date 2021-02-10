class AddNotificationColumnsToAssignmentSchedule < ActiveRecord::Migration[5.1]
  def change
    add_column :assignment_schedules, :opening_notification_sent_at, :datetime
    add_column :assignment_schedules, :closing_notification_sent_at, :datetime
  end
end
